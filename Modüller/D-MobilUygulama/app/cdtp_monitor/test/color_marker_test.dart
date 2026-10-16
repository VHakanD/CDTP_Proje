import 'dart:typed_data';

import 'package:cdtp_monitor/data/services/tracker/color_marker.dart';
import 'package:flutter_test/flutter_test.dart';

/// 160×120 gri kare; (cx, cy) çevresinde [r] yarıçaplı macenta leke.
YuvFrame frame({int? cx, int? cy, int r = 10}) {
  const w = 160, h = 120;
  final y = Uint8List(w * h)..fillRange(0, w * h, 120);
  final u = Uint8List((w ~/ 2) * (h ~/ 2))..fillRange(0, (w ~/ 2) * (h ~/ 2), 128);
  final v = Uint8List.fromList(u);
  if (cx != null && cy != null) {
    for (var py = cy - r; py < cy + r; py++) {
      for (var px = cx - r; px < cx + r; px++) {
        final i = (py ~/ 2) * (w ~/ 2) + (px ~/ 2);
        u[i] = 200;
        v[i] = 200;
      }
    }
  }
  return YuvFrame(width: w, height: h, y: y, u: u, v: v, yRowStride: w, uvRowStride: w ~/ 2, uvPixelStride: 1);
}

void main() {
  test('finds_magenta_marker_center', () {
    final hit = findMarker(frame(cx: 40, cy: 90), MarkerColor.magenta, stride: 2);
    expect(hit, isNotNull);
    expect(hit!.center.dx, closeTo(40 / 160, 0.03));
    expect(hit.center.dy, closeTo(90 / 120, 0.03));
    expect(hit.confidence, greaterThan(0.6));
  });

  test('no_marker_returns_null', () {
    expect(findMarker(frame(), MarkerColor.magenta), isNull);
  });

  test('rotate_90_to_portrait', () {
    expect(rotateToPortrait(const Offset(0.2, 0.1), 90), const Offset(0.9, 0.2));
    expect(rotateToPortrait(const Offset(0.2, 0.1), 0), const Offset(0.2, 0.1));
  });
}
