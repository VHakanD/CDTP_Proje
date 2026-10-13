import 'package:flutter/material.dart';

/// Ek paket kullanmadan basit cizgi grafik (son N ornek).
/// Panelde egim ve batarya gecmisini gostermek icin kullanilir.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 80,
    this.minY,
    this.maxY,
    this.referenceLines = const [],
  });

  final List<double> values;
  final Color color;
  final double height;
  final double? minY;
  final double? maxY;

  /// Yatay referans cizgileri (orn. +10° / -10°).
  final List<double> referenceLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Veri bekleniyor',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(
          values: values,
          color: color,
          gridColor: theme.colorScheme.outline,
          minY: minY,
          maxY: maxY,
          referenceLines: referenceLines,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.referenceLines,
    this.minY,
    this.maxY,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;
  final List<double> referenceLines;
  final double? minY;
  final double? maxY;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = minY ?? values.reduce((a, b) => a < b ? a : b);
    var hi = maxY ?? values.reduce((a, b) => a > b ? a : b);
    if ((hi - lo).abs() < 1e-6) {
      lo -= 1;
      hi += 1;
    }
    double y(double v) => size.height - ((v.clamp(lo, hi) - lo) / (hi - lo)) * size.height;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final r in referenceLines) {
      canvas.drawLine(Offset(0, y(r)), Offset(size.width, y(r)), grid);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      if (i == 0) {
        path.moveTo(x, y(values[i]));
      } else {
        path.lineTo(x, y(values[i]));
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}
