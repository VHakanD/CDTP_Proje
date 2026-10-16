import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_scope.dart';
import '../../../../domain/models/test_report.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/verdict_box.dart';
import '../../../core/widgets/wf_parts.dart';
import '../../reports/widgets/criteria_table.dart';

/// 06 · Sonuç. Rapor burada zaten mühürlüdür; düzenleme düğmesi yoktur.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.reportId});
  final String reportId;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Test sonucu'), automaticallyImplyLeading: false),
      body: FutureBuilder<TestReport?>(
        future: scope.reports.byId(reportId),
        builder: (context, snap) {
          final r = snap.data;
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (r == null) return const Center(child: Text('Rapor bulunamadı.'));
          final fails = [for (final c in r.criteria) if (c.reason != null) '${c.name}: ${c.reason}'];
          return WfPage(
            bottom: Column(mainAxisSize: MainAxisSize.min, children: [
              FilledButton(onPressed: () => context.go('/reports/${r.id}'), child: const Text('Raporu aç')),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await scope.tracking.close();
                      if (context.mounted) context.go('/tasks');
                    },
                    child: const Text('Yeni test'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await scope.tracking.close();
                      if (context.mounted) context.go('/dashboard');
                    },
                    child: const Text('Ana panel'),
                  ),
                ),
              ]),
            ]),
            children: [
              Text('Görev ${r.task.module} · ${r.task.label}'),
              Text('${fmtDateTime(r.startedAt)} → ${fmtTime(r.endedAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.mid)),
              const SizedBox(height: 12),
              VerdictBox(verdict: r.verdict, passed: r.passed, scored: r.scored),
              const SectionLabel('Ölçütler'),
              CriteriaTable(r.criteria),
              if (fails.isNotEmpty) ...[
                const SizedBox(height: 8),
                WfBox(dashed: true, child: Text(fails.join('\n'), style: const TextStyle(fontSize: 12))),
              ],
              const SectionLabel('Kayıt'),
              WfBox(
                child: Text(r.videoPath == null
                    ? 'Zaman damgalı olay kaydı · ${r.events.length} olay (simülatörde video yok)'
                    : '▶ Video · ${fmtSecs(r.duration)} + zaman damgalı olay kaydı'),
              ),
              const SizedBox(height: 10),
              Row(children: [
                const Pill('Kilitli', solid: true),
                const SizedBox(width: 6),
                const Text('Kayıt mühürlendi'),
              ]),
              const SizedBox(height: 2),
              Text('SHA-256 ${shortHash(r.hash)}', style: const TextStyle(fontSize: 12, color: AppColors.mid)),
            ],
          );
        },
      ),
    );
  }
}
