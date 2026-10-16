import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/motion.dart';

/// Zorunlu yön göstergesi. Varyant B kararı: kamera görüntüsünün sol kenarında,
/// dikey ortada, küçük kutu ([width] = 64).
class DirectionIndicator extends StatelessWidget {
  const DirectionIndicator(this.heading, {super.key});

  static const width = 64.0;
  final Heading heading;

  @override
  Widget build(BuildContext context) {
    final turns = switch (heading) {
      Heading.forward => 0.0,
      Heading.right => 0.25,
      Heading.backward => 0.5,
      Heading.left => 0.75,
      Heading.stopped => 0.0,
    };
    return Semantics(
      label: 'Yön: ${heading.label}',
      child: Container(
        key: const Key('direction-indicator'),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 36,
            height: 36,
            child: heading == Heading.stopped
                ? const Center(child: SizedBox(width: 24, height: 6, child: ColoredBox(color: Colors.white)))
                : Transform.rotate(
                    angle: turns * 2 * math.pi,
                    child: const Icon(Icons.arrow_upward_rounded, size: 36, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 2),
          Text(heading.label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
    );
  }
}
