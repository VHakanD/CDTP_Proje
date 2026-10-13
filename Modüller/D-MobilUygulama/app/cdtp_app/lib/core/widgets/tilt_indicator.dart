import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../utils/formatters.dart';

/// Robotun govde egimini yandan gorunus olarak cizer.
/// Dikey cizgi = 0°, govde cubugu egim acisi kadar yatar.
class TiltIndicator extends StatelessWidget {
  const TiltIndicator({super.key, required this.tiltDeg, this.warnDeg = 10, this.size = 140});

  final double? tiltDeg;

  /// Bu acinin ustunde govde uyari renginde cizilir.
  final double warnDeg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tilt = tiltDeg;
    final color = tilt == null
        ? AppColors.missing
        : tilt.abs() >= warnDeg
            ? AppColors.fail
            : theme.colorScheme.secondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _TiltPainter(
              tiltDeg: tilt ?? 0,
              bodyColor: color,
              guideColor: theme.colorScheme.outline,
              groundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Fmt.degrees(tilt),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TiltPainter extends CustomPainter {
  _TiltPainter({
    required this.tiltDeg,
    required this.bodyColor,
    required this.guideColor,
    required this.groundColor,
  });

  final double tiltDeg;
  final Color bodyColor;
  final Color guideColor;
  final Color groundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height * 0.85);
    final length = size.height * 0.7;

    // +-10° bolgesi (sartnamedeki toparlanma testi sinirlari)
    final arc = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const tenDeg = 10 * math.pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: length),
      -math.pi / 2 - tenDeg,
      2 * tenDeg,
      false,
      arc,
    );

    // Dikey referans cizgisi
    final guide = Paint()
      ..color = guideColor
      ..strokeWidth = 1.5;
    canvas.drawLine(pivot, pivot.translate(0, -length), guide);

    // Zemin
    final ground = Paint()
      ..color = groundColor
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.15, pivot.dy + 10),
      Offset(size.width * 0.85, pivot.dy + 10),
      ground,
    );

    // Govde
    final rad = tiltDeg.clamp(-90, 90) * math.pi / 180;
    final top = pivot + Offset(math.sin(rad) * length, -math.cos(rad) * length);
    final body = Paint()
      ..color = bodyColor
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, top, body);

    // Teker
    canvas.drawCircle(pivot, 10, Paint()..color = groundColor);
  }

  @override
  bool shouldRepaint(_TiltPainter old) =>
      old.tiltDeg != tiltDeg || old.bodyColor != bodyColor;
}
