import 'dart:convert';

import '../../domain/models/criterion.dart';
import '../../domain/models/test_report.dart';
import '../../domain/models/test_task.dart';
import '../../domain/use_cases/report_chain.dart';
import '../../domain/use_cases/task_evaluator.dart';
import '../services/report_file_service.dart';

/// Mühürlenmemiş rapor taslağı (kamera ekranı test bitince doldurur).
class ReportDraft {
  const ReportDraft({
    required this.task,
    required this.startedAt,
    required this.endedAt,
    required this.criteria,
    required this.events,
    required this.conditions,
    required this.telemetryCount,
    this.expected,
    this.videoPath,
  });

  final TaskKind task;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<Criterion> criteria;
  final List<(int, String)> events;
  final Map<String, dynamic> conditions;
  final int telemetryCount;
  final String? expected;
  final String? videoPath;
}

/// Raporların tek doğruluk kaynağı. Yalnız ekleme ve okuma; silme/güncelleme yok.
class ReportRepository {
  ReportRepository(this._files, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final ReportFileService _files;
  final DateTime Function() _now;
  List<TestReport>? _cache;

  Future<List<TestReport>> _load() async {
    return _cache ??= [
      for (final l in await _files.readLines())
        TestReport.fromJson(jsonDecode(l) as Map<String, dynamic>)
    ];
  }

  /// Eskiden yeniye.
  Future<List<TestReport>> all() async => List.unmodifiable(await _load());

  Future<TestReport?> byId(String id) async {
    for (final r in await _load()) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<TestReport> seal(ReportDraft d) async {
    final list = await _load();
    final prev = list.isEmpty ? ReportChain.genesis : list.last.hash;
    final sealedAt = _now();
    final id = 'T${sealedAt.toUtc().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14)}'
        '-${list.length + 1}';
    final draft = TestReport(
      id: id,
      task: d.task,
      startedAt: d.startedAt,
      endedAt: d.endedAt,
      verdict: TaskRun.verdictOf(d.criteria),
      criteria: d.criteria,
      events: d.events,
      conditions: d.conditions,
      telemetryCount: d.telemetryCount,
      expected: d.expected,
      videoPath: d.videoPath,
      prevHash: prev,
      hash: '',
      sealedAt: sealedAt,
    );
    final sealed = TestReport.fromJson({...draft.body(), 'hash': ReportChain.hashOf(draft.body())});
    await _files.appendLine(jsonEncode(sealed.toJson()));
    list.add(sealed);
    return sealed;
  }

  /// Rapor ve ondan önceki zincir dosyadan yeniden okunarak doğrulanır.
  Future<ChainCheck> verify(String id) async {
    _cache = null;
    final list = await _load();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx < 0) return ChainCheck.broken(id);
    return ReportChain.verify(list.sublist(0, idx + 1));
  }

  Future<String> exportJson(String id) async {
    final r = await byId(id);
    if (r == null) throw StateError('Rapor bulunamadı: $id');
    return _files.export('$id.json', const JsonEncoder.withIndent('  ').convert(r.toJson()));
  }
}
