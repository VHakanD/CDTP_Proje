import 'package:flutter/material.dart';

import '../../../../domain/models/criterion.dart';
import '../../../core/theme.dart';

/// Ölçüt | Ölçülen | Hedef | Sonuç (wireframe 06–07).
class CriteriaTable extends StatelessWidget {
  const CriteriaTable(this.criteria, {super.key});
  final List<Criterion> criteria;

  @override
  Widget build(BuildContext context) {
    TableRow row(List<Widget> cells, {bool head = false}) => TableRow(
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: head ? AppColors.line : AppColors.hair))),
          children: [for (final c in cells) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: c)],
        );
    const h = TextStyle(fontSize: 11, color: AppColors.mid);
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.2), 3: IntrinsicColumnWidth()},
      children: [
        row(const [Text('Ölçüt', style: h), Text('Ölçülen', style: h), Text('Hedef', style: h), Text('Sonuç', style: h)],
            head: true),
        for (final c in criteria)
          row([
            Text(c.name),
            Text(c.measured + (c.reason == null ? '' : '\n${c.reason}'),
                style: TextStyle(fontSize: c.reason == null ? 14 : 12)),
            Text(c.target, style: const TextStyle(color: AppColors.mid, fontSize: 12)),
            Text(
              switch (c.result) {
                CriterionResult.pass => '✓',
                CriterionResult.fail => '✕',
                CriterionResult.info => 'bilgi',
              },
              textAlign: TextAlign.right,
              style: TextStyle(
                color: switch (c.result) {
                  CriterionResult.pass => AppColors.pass,
                  CriterionResult.fail => AppColors.fail,
                  CriterionResult.info => AppColors.mid,
                },
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
      ],
    );
  }
}
