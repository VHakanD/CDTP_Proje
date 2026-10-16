import 'dart:math' as math;
import 'dart:ui';

/// Sensör karesi (0..1 normalize, en/boy [sensorAspect]) ekrandaki alana
/// "cover" kırpmasıyla yerleştirilir. 1:1 / 4:3 / 9:16 seçimi yalnız bu
/// eşlemeyi değiştirir; ölçüm koordinatları değişmez.
class FrameMapping {
  FrameMapping(this.display, this.sensorAspect) {
    final scale = math.max(display.width / sensorAspect, display.height / 1);
    drawn = Size(sensorAspect * scale, scale);
    origin = Offset((display.width - drawn.width) / 2, (display.height - drawn.height) / 2);
  }

  final Size display;
  final double sensorAspect;
  late final Size drawn;
  late final Offset origin;

  Offset toDisplay(Offset n) => origin + Offset(n.dx * drawn.width, n.dy * drawn.height);

  Offset toSensor(Offset d) => Offset((d.dx - origin.dx) / drawn.width, (d.dy - origin.dy) / drawn.height);

  Rect rectToDisplay(Rect n) => Rect.fromPoints(toDisplay(n.topLeft), toDisplay(n.bottomRight));
}
