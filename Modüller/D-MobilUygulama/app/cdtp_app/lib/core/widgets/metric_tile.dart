import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Tek bir olcum degerini (etiket + buyuk deger + alt bilgi) gosteren kutu.
/// Deger null ise "—" ve gri renk ile "veri yok" durumu gosterilir.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
    this.available = true,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;

  /// false ise kutu soluk cizilir (ornegin kamera tespiti henuz yok).
  final bool available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: available ? (valueColor ?? theme.colorScheme.onSurface) : AppColors.missing,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Metrik kutularini ekran genisligine gore 2-4 sutunlu izgarada dizer.
class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.children, this.minTileWidth = 150});

  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = (constraints.maxWidth / minTileWidth).floor().clamp(2, 4);
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final c in children) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}
