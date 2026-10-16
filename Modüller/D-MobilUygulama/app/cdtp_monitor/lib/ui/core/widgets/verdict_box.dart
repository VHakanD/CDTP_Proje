import 'package:flutter/material.dart';

import '../../../domain/models/criterion.dart';
import '../theme.dart';

/// Büyük GEÇTİ / KALDI kutusu. KALDI renge ek olarak kesikli kenarla ayrışır.
class VerdictBox extends StatelessWidget {
  const VerdictBox({super.key, required this.verdict, required this.passed, required this.scored});
  final Verdict verdict;
  final int passed;
  final int scored;

  @override
  Widget build(BuildContext context) {
    final pass = verdict == Verdict.pass;
    final color = pass ? AppColors.pass : AppColors.fail;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: pass ? Border.all(color: color, width: 2) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      foregroundDecoration: pass ? null : _DashedBorder(color),
      child: Column(children: [
        Text(verdict.label.split('').join(' '),
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color, letterSpacing: 4)),
        const SizedBox(height: 4),
        Text('$passed / $scored ölçüt sağlandı'),
      ]),
    );
  }
}

class _DashedBorder extends Decoration {
  const _DashedBorder(this.color);
  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DashPainter(color);
}

class _DashPainter extends BoxPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas c, Offset o, ImageConfiguration cfg) {
    final r = o & (cfg.size ?? Size.zero);
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    void dashed(Offset a, Offset b) {
      final len = (b - a).distance;
      final dir = (b - a) / len;
      for (var d = 0.0; d < len; d += 10) {
        c.drawLine(a + dir * d, a + dir * (d + 6 > len ? len : d + 6), p);
      }
    }

    dashed(r.topLeft, r.topRight);
    dashed(r.topRight, r.bottomRight);
    dashed(r.bottomRight, r.bottomLeft);
    dashed(r.bottomLeft, r.topLeft);
  }
}
