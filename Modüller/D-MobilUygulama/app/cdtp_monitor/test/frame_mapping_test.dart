import 'dart:ui';

import 'package:cdtp_monitor/ui/core/camera/frame_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('square_sensor_in_square_display_is_identity_scale', () {
    final m = FrameMapping(const Size(300, 300), 1);
    expect(m.toDisplay(const Offset(0.5, 0.5)), const Offset(150, 150));
    expect(m.origin, Offset.zero);
  });

  test('tall_display_crops_sides', () {
    final m = FrameMapping(const Size(180, 320), 1); // 9:16
    expect(m.drawn, const Size(320, 320));
    expect(m.origin.dx, -70);
    expect(m.toDisplay(const Offset(0.5, 0.5)), const Offset(90, 160));
  });

  test('round_trip', () {
    final m = FrameMapping(const Size(240, 320), 9 / 16);
    const p = Offset(0.3, 0.7);
    final back = m.toSensor(m.toDisplay(p));
    expect(back.dx, closeTo(p.dx, 1e-9));
    expect(back.dy, closeTo(p.dy, 1e-9));
  });
}
