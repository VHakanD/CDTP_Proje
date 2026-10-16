import 'package:flutter/material.dart';

import '../../../domain/models/link_health.dart';
import '../format.dart';
import '../theme.dart';

/// Bağlantı rozeti: ● Bağlı · 0,4 s / ◐ Gecikme / ○ Koptu (wireframe 02).
class LinkBadge extends StatelessWidget {
  const LinkBadge(this.state, {super.key, this.compact = false});
  final LinkState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final since = state.sinceLastTelemetry;
    final (dot, label, color) = switch (state.level) {
      LinkLevel.ok => ('●', 'Bağlı', AppColors.pass),
      LinkLevel.slow => ('◐', 'Gecikme', AppColors.warn),
      LinkLevel.lost => ('○', 'Koptu', AppColors.fail),
      LinkLevel.connecting => ('◌', 'Bağlanıyor', AppColors.mid),
      LinkLevel.disconnected => ('○', 'Bağlı değil', AppColors.mid),
    };
    final age = since == null || state.level == LinkLevel.disconnected
        ? ''
        : compact
            ? ' ${fmtSecs(since)}'
            : ' · son paket ${fmtSecs(since)}';
    return Semantics(
      label: 'Bağlantı: $label',
      child: Text.rich(TextSpan(children: [
        TextSpan(text: '$dot ', style: TextStyle(color: color)),
        TextSpan(text: '$label$age'),
      ]), style: const TextStyle(fontSize: 12)),
    );
  }
}
