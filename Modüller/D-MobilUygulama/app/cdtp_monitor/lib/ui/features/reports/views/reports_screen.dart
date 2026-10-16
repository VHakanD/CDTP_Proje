import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_scope.dart';
import '../../../../domain/models/criterion.dart';
import '../../../../domain/models/test_report.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/wf_parts.dart';

/// 07a · Rapor geçmişi. Yalnız okunur; silme yok.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = AppScope.of(context).reports;
    return Scaffold(
      appBar: AppBar(title: const Text('Rapor geçmişi')),
      body: FutureBuilder<List<TestReport>>(
        future: reports.all(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!.reversed.toList();
          if (list.isEmpty) {
            return const WfPage(children: [
              WfBox(
                dashed: true,
                child: Text('Henüz rapor yok. Bir görev seçip testi başlattığınızda sonuç burada görünür.'),
              ),
            ]);
          }
          return WfPage(children: [
            Text('${list.length} rapor · en yeni üstte', style: const TextStyle(fontSize: 12, color: AppColors.mid)),
            const SizedBox(height: 8),
            WfBox(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final r in list) ...[
                  ListTile(
                    onTap: () => context.push('/reports/${r.id}'),
                    title: Text('${r.task.module} · ${r.task.label}'),
                    subtitle: Text('${fmtDateTime(r.startedAt)}\nKilitli ${shortHash(r.hash)}',
                        style: const TextStyle(fontSize: 11)),
                    isThreeLine: true,
                    trailing: Pill(r.verdict.label,
                        solid: r.verdict == Verdict.pass,
                        color: r.verdict == Verdict.pass ? AppColors.pass : AppColors.fail),
                  ),
                  if (r != list.last) const Divider(),
                ],
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
