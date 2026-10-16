import 'criterion.dart';
import 'test_task.dart';

/// Mühürlenmiş test raporu (wireframe 06–07). Oluşturulduktan sonra değişmez.
class TestReport {
  const TestReport({
    required this.id,
    required this.task,
    required this.startedAt,
    required this.endedAt,
    required this.verdict,
    required this.criteria,
    required this.events,
    required this.conditions,
    required this.telemetryCount,
    required this.prevHash,
    required this.hash,
    required this.sealedAt,
    this.expected,
    this.videoPath,
  });

  final String id;
  final TaskKind task;
  final DateTime startedAt;
  final DateTime endedAt;
  final Verdict verdict;
  final List<Criterion> criteria;

  /// Testin başından itibaren ms ve açıklama.
  final List<(int, String)> events;

  /// Ölçek, beklenen yön, görüntü oranı gibi test koşulları.
  final Map<String, dynamic> conditions;
  final int telemetryCount;
  final String? expected;
  final String? videoPath;
  final String prevHash;
  final String hash;
  final DateTime sealedAt;

  Duration get duration => endedAt.difference(startedAt);
  int get passed => criteria.where((c) => c.result == CriterionResult.pass).length;
  int get scored => criteria.where((c) => c.result != CriterionResult.info).length;

  /// Hash'e giren gövde ([hash] hariç her şey).
  Map<String, dynamic> body() => {
        'id': id,
        'task': task.name,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
        'verdict': verdict.name,
        'criteria': [for (final c in criteria) c.toJson()],
        'events': [for (final e in events) [e.$1, e.$2]],
        'conditions': conditions,
        'telemetry_count': telemetryCount,
        'expected': expected,
        'video_path': videoPath,
        'prev_hash': prevHash,
        'sealed_at': sealedAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toJson() => {...body(), 'hash': hash};

  factory TestReport.fromJson(Map<String, dynamic> j) => TestReport(
        id: j['id'] as String,
        task: TaskKind.values.byName(j['task'] as String),
        startedAt: DateTime.parse(j['started_at'] as String).toLocal(),
        endedAt: DateTime.parse(j['ended_at'] as String).toLocal(),
        verdict: Verdict.values.byName(j['verdict'] as String),
        criteria: [
          for (final c in j['criteria'] as List) Criterion.fromJson(c as Map<String, dynamic>)
        ],
        events: [
          for (final e in j['events'] as List) ((e as List)[0] as int, e[1] as String)
        ],
        conditions: Map<String, dynamic>.from(j['conditions'] as Map),
        telemetryCount: j['telemetry_count'] as int,
        expected: j['expected'] as String?,
        videoPath: j['video_path'] as String?,
        prevHash: j['prev_hash'] as String,
        hash: j['hash'] as String,
        sealedAt: DateTime.parse(j['sealed_at'] as String).toLocal(),
      );
}
