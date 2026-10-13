import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_chip.dart';
import '../application/robot_connection_controller.dart';
import '../domain/connection_state.dart';

Color linkPhaseColor(LinkPhase p) => switch (p) {
      LinkPhase.connected => AppColors.pass,
      LinkPhase.connecting => AppColors.warning,
      LinkPhase.stale => AppColors.fail,
      LinkPhase.disconnected => AppColors.missing,
    };

/// Ust bardaki baglanti durumu: "Bagli · 1,0 Hz".
class ConnectionBadge extends ConsumerWidget {
  const ConnectionBadge({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(robotConnectionProvider);
    final hz = s.stats.measuredHz;
    final label = s.phase == LinkPhase.connected && hz != null
        ? '${s.phase.label} · ${Fmt.number(hz, digits: 1)} Hz'
        : s.phase.label;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: StatusChip(label: label, color: linkPhaseColor(s.phase)),
    );
  }
}
