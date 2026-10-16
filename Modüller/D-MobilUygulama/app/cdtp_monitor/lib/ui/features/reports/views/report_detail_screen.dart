import 'package:flutter/material.dart';

import '../../../../app_scope.dart';
import '../../../../domain/models/test_report.dart';
import '../../../../domain/use_cases/report_chain.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/wf_parts.dart';
import '../widgets/criteria_table.dart';

/// 07b · Rapor detayı: olay kaydı, ölçütler, bütünlük doğrulama, dışa aktarma.
class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.reportId});
  final String reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ChainCheck? check;
  String? exported;

  @override
  Widget build(BuildContext context) {
    final reports = AppScope.of(context).reports;
    return Scaffold(
      appBar: AppBar(title: const Text('Rapor')),
      body: FutureBuilder<TestReport?>(
        future: reports.byId(widget.reportId),
        builder: (context, snap) {
          final r = snap.data;
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (r == null) return const Center(child: Text('Rapor bulunamadı.'));
          return WfPage(
            bottom: FilledButton(
              onPressed: () async {
                final path = await reports.exportJson(r.id);
                setState(() => exported = path);
              },
              child: const Text('Dışa aktar (JSON)'),
            ),
            children: [
              Row(children: [
                const Pill('Kilitli', solid: true),
                const SizedBox(width: 6),
                const Expanded(child: Text('Değiştirilemez kayıt', style: TextStyle(fontSize: 12))),
              ]),
              const SizedBox(height: 8),
              Text('Görev ${r.task.module} · ${r.task.label}'),
              Text('${fmtDateTime(r.startedAt)} → ${fmtTime(r.endedAt)} · ${fmtSecs(r.duration)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.mid)),
              Text('Karar: ${r.verdict.label} (${r.passed}/${r.scored})',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (r.videoPath != null) ...[
                const SectionLabel('Video'),
                WfBox(child: Text(r.videoPath!, style: const TextStyle(fontSize: 11))),
              ],
              const SectionLabel('Ölçülen değerler'),
              CriteriaTable(r.criteria),
              const SectionLabel('Olay kaydı (zaman damgalı)'),
              WfBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final e in r.events)
                    Text('${fmtClock(Duration(milliseconds: e.$1))}  ${e.$2}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Telemetri: ${r.telemetryCount} paket', style: const TextStyle(fontSize: 12, color: AppColors.mid)),
                ]),
              ),
              const SectionLabel('Test koşulları'),
              WfBox(
                child: Column(children: [
                  KvRow('Görüntü oranı', '${r.conditions['ratio'] ?? '—'}'),
                  KvRow('Kamera', '${r.conditions['tracker'] ?? '—'}'),
                  KvRow('Beklenen yön', r.expected ?? '—'),
                  KvRow('En uzun kopma', '${r.conditions['max_gap_ms'] ?? '—'} ms'),
                ]),
              ),
              const SectionLabel('Doğrulama'),
              WfBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectableText('SHA-256 ${r.hash}', style: const TextStyle(fontSize: 11)),
                  Text('Önceki ${shortHash(r.prevHash)} · mühür ${fmtDateTime(r.sealedAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.mid)),
                  const SizedBox(height: 6),
                  Row(children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                      onPressed: () async {
                        final c = await reports.verify(r.id);
                        setState(() => check = c);
                      },
                      child: const Text('Bütünlüğü doğrula'),
                    ),
                    const SizedBox(width: 8),
                    if (check != null)
                      Expanded(
                        child: Text(
                          check!.ok ? '✓ değişmemiş' : '✕ değişmiş (${check!.brokenAtId})',
                          style: TextStyle(color: check!.ok ? AppColors.pass : AppColors.fail),
                        ),
                      ),
                  ]),
                ]),
              ),
              if (exported != null) ...[
                const SizedBox(height: 8),
                Text('Kaydedildi: $exported', style: const TextStyle(fontSize: 11, color: AppColors.mid)),
              ],
            ],
          );
        },
      ),
    );
  }
}
