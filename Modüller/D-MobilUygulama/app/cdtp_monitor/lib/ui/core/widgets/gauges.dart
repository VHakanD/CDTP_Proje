import 'package:flutter/material.dart';

import '../theme.dart';

/// -30°..+30° yatay eğim göstergesi (wireframe 02).
class TiltGauge extends StatelessWidget {
  const TiltGauge(this.deg, {super.key});
  final double? deg;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 40, width: double.infinity, child: CustomPaint(painter: _TiltPainter(deg)));
}

class _TiltPainter extends CustomPainter {
  _TiltPainter(this.deg);
  final double? deg;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    final y = s.height * 0.45;
    c.drawLine(Offset(0, y), Offset(s.width, y), p);
    for (var i = 0; i <= 4; i++) {
      final x = s.width * i / 4;
      c.drawLine(Offset(x, y - 6), Offset(x, y + 6), p);
      _label(c, ['-30', '-15', '0°', '+15', '+30'][i], Offset(x, s.height - 2), i);
    }
    final d = deg;
    if (d == null) return;
    final x = s.width * ((d.clamp(-30, 30) + 30) / 60);
    final tri = Path()
      ..moveTo(x, y - 2)
      ..lineTo(x - 6, y - 12)
      ..lineTo(x + 6, y - 12)
      ..close();
    c.drawPath(tri, Paint()..color = d.abs() > 8 ? AppColors.warn : AppColors.ink);
  }

  void _label(Canvas c, String t, Offset at, int i) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: const TextStyle(fontSize: 9, color: AppColors.mid)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = i == 0 ? 0.0 : (i == 4 ? -tp.width : -tp.width / 2);
    tp.paint(c, at + Offset(dx, -tp.height));
  }

  @override
  bool shouldRepaint(_TiltPainter o) => o.deg != deg;
}

/// Son 60 s eğim grafiği. [values] eskiden yeniye, 1 Hz.
class Sparkline extends StatelessWidget {
  const Sparkline(this.values, {super.key, this.span = 60, this.range = 15});
  final List<double> values;
  final int span;
  final double range;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 70,
        width: double.infinity,
        child: CustomPaint(painter: _SparkPainter(values, span, range)),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.v, this.span, this.range);
  final List<double> v;
  final int span;
  final double range;

  @override
  void paint(Canvas c, Size s) {
    final h = s.height - 12;
    final mid = h / 2;
    final dash = Paint()
      ..color = AppColors.hair
      ..strokeWidth = 1;
    for (var x = 0.0; x < s.width; x += 6) {
      c.drawLine(Offset(x, mid), Offset(x + 3, mid), dash);
    }
    if (v.length >= 2) {
      final pts = v.length > span ? v.sublist(v.length - span) : v;
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final x = s.width * (span - pts.length + i) / (span - 1);
        final y = mid - (pts[i].clamp(-range, range) / range) * mid;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      c.drawPath(
          path,
          Paint()
            ..color = AppColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
    _t(c, '-$span s', Offset(0, s.height), false);
    _t(c, 'şimdi', Offset(s.width, s.height), true);
  }

  void _t(Canvas c, String t, Offset at, bool right) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: const TextStyle(fontSize: 9, color: AppColors.mid)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(right ? tp.width : 0, tp.height));
  }

  @override
  bool shouldRepaint(_SparkPainter o) => true;
}

/// Doluluk çubuğu (pil, bağlantı sağlığı).
class Meter extends StatelessWidget {
  const Meter(this.fraction, {super.key, this.color = AppColors.line});
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 10,
        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(2)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0, 1).toDouble(),
          heightFactor: 1,
          child: ColoredBox(color: color),
        ),
      );
}
