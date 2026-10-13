import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/evaluation.dart';

Color verdictColor(Verdict v) => switch (v) {
      Verdict.passed => AppColors.pass,
      Verdict.failed => AppColors.fail,
      Verdict.incomplete => AppColors.warning,
    };

Color criterionColor(CriterionStatus s) => switch (s) {
      CriterionStatus.pass => AppColors.pass,
      CriterionStatus.fail => AppColors.fail,
      CriterionStatus.missing => AppColors.missing,
    };

/// Gorev modul harfi icin kare rozet (A, B, C, E).
class ModuleBadge extends StatelessWidget {
  const ModuleBadge(this.module, {super.key, this.size = 40});

  final String module;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        module,
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
