import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/file_export.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/key_value_table.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../connection/domain/robot_telemetry.dart';
import '../../tasks/domain/evaluation.dart';
import '../../tasks/domain/test_recording.dart';
import '../../tasks/presentation/verdict_style.dart';
import '../domain/test_report.dart';

/// Tek bir test raporunun ayrintisi. Sadece okunur; duzenleme yoktur.
class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.report});

  final TestReport report;

  Future<void> _copyJson(BuildContext context) async {
    final text = const JsonEncoder.withIndent('  ').convert(report.toExportJson());
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rapor JSON panoya kopyalandı')));
    }
  }

  Future<void> _saveJson(BuildContext context) async {
    final text = const JsonEncoder.withIndent('  ').convert(report.toExportJson());
    final path = await saveTextFile('${report.testId}.json', text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(path == null ? 'Bu platformda dosya kaydı yok' : 'Kaydedildi: $path')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = report.payload;
    final criteria = report.criteria;
    final metrics = (p['metrics'] as Map?)?.cast<String, Object?>() ?? const {};
    final video = (p['video'] as Map?)?.cast<String, Object?>();
    final robot = (p['robot'] as Map?)?.cast<String, Object?>();
    final tracker = (p['tracker'] as Map?)?.cast<String, Object?>();
    final link = (p['link'] as Map?)?.cast<String, Object?>() ?? const {};
    final telemetry = ((p['telemetry'] as List?) ?? const [])
        .map((e) => RobotTelemetry.fromStoredJson((e as Map).cast<String, Object?>()))
        .toList();
    final endReason = EndReason.values.asNameMap()[p['end_reason']];
    final endedAt = DateTime.tryParse(p['ended_at'] as String? ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text('Rapor #${report.seq}'),
        actions: [
          IconButton(
            tooltip: 'JSON kopyala',
            onPressed: () => _copyJson(context),
            icon: const Icon(Icons.copy_all_outlined),
          ),
          if (!kIsWeb)
            IconButton(
              tooltip: 'JSON dosyası olarak kaydet',
              onPressed: () => _saveJson(context),
              icon: const Icon(Icons.save_alt_outlined),
            ),
          // TODO(rapor): PDF disa aktarma (pdf paketi) ileride eklenecek.
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VerdictBanner(report: report),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Test bilgisi',
            child: KeyValueTable(rows: [
              ('Test no', report.testId),
              ('Görev', '${report.task.module} · ${report.task.title}'),
              ('Puan tablosu', report.task.rubric),
              if (p['params'] is Map && (p['params'] as Map)['expected_direction'] != null)
                ('Beklenen yön', '${(p['params'] as Map)['expected_direction']}'),
              ('Başlangıç', Fmt.dateTime(report.startedAt)),
              ('Bitiş', endedAt == null ? Fmt.empty : Fmt.dateTime(endedAt)),
              ('Süre', Fmt.clockPrecise(Duration(milliseconds: report.durationMs))),
              ('Bitiş nedeni', endReason?.label ?? Fmt.empty),
              ('Robot', robot == null ? Fmt.empty : '${robot['device']} (${robot['firmware']})'),
              ('Kamera tespiti', '${tracker?['name'] ?? Fmt.empty}'),
              ('Telemetri', '${link['telemetry_count'] ?? 0} paket, '
                  '${Fmt.number(link['rate_hz'] as num?, digits: 2)} Hz, '
                  'en uzun boşluk ${Fmt.seconds(link['max_gap_s'] as num?)}'),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Kriterler',
            child: Column(
              children: [for (final c in criteria) _CriterionRow(c)],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Ölçülen değerler',
            child: KeyValueTable(rows: [
              for (final e in metrics.entries) (e.key, _fmtValue(e.value)),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Video kaydı',
            child: video == null
                ? const Text('Video kaydı yok')
                : KeyValueTable(rows: [
                    ('Dosya', '${video['path']}'),
                    ('Boyut', '${((video['size_bytes'] as num? ?? 0) / 1048576).toStringAsFixed(1)} MB'),
                    ('SHA-256', '${video['sha256']}'),
                  ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Telemetri kayıtları (${telemetry.length})',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _TelemetryTable(samples: telemetry, start: report.startedAt),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Bütünlük',
            child: KeyValueTable(rows: [
              ('Zincir sırası', '#${report.seq}'),
              ('Kayıt zamanı', Fmt.dateTime(report.createdAt)),
              ('Önceki hash', report.prevHash),
              ('Hash (SHA-256)', report.hash),
            ]),
          ),
        ],
      ),
    );
  }

  static String _fmtValue(Object? v) => switch (v) {
        null => Fmt.empty,
        double d => Fmt.number(d, digits: 2),
        bool b => Fmt.boolTr(b),
        _ => v.toString(),
      };
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.report});

  final TestReport report;

  @override
  Widget build(BuildContext context) {
    final color = verdictColor(report.verdict);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.verdict.label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  '${report.task.module} · ${report.task.title}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, color: Colors.white),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow(this.c);

  final CriterionResult c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.required ? c.label : '${c.label}  (bilgi)',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text('Beklenen: ${c.expected}', style: muted),
                Text('Ölçülen: ${c.measured}', style: muted),
                Text('Kaynak: ${c.source.label}', style: muted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(label: c.status.label, color: criterionColor(c.status), dense: true),
        ],
      ),
    );
  }
}

/// Test boyunca alinan telemetri satirlari (t+ saniye, sarj, egim, sarj durumu, robot durumu).
class _TelemetryTable extends StatelessWidget {
  const _TelemetryTable({required this.samples, required this.start});

  final List<RobotTelemetry> samples;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) return const Text('Telemetri yok');
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final header = style?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary);

    TableRow row(List<String> cells, TextStyle? s) => TableRow(children: [
          for (final c in cells)
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(c, style: s)),
        ]);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          row(['t+ (s)      ', 'Şarj      ', 'Eğim      ', 'Şarjda      ', 'Durum'], header),
          for (final t in samples)
            row([
              Fmt.number(t.receivedAt.difference(start).inMilliseconds / 1000, digits: 1),
              Fmt.percent(t.batteryPct),
              Fmt.degrees(t.tiltDeg),
              Fmt.boolTr(t.charging),
              t.state?.label ?? Fmt.empty,
            ], style),
        ],
      ),
    );
  }
}
