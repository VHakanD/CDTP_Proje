import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/tracking_repository.dart';
import '../../../data/services/tracker/sim_tracker.dart';
import '../theme.dart';
import 'frame_mapping.dart';

/// Kamera görüntüsü (gerçek ya da simülatör sahnesi) + üstüne çizilen katmanlar.
/// [overlay], ekran alanı ve sensör→ekran eşlemesiyle çağrılır.
class CameraSurface extends StatelessWidget {
  const CameraSurface({
    super.key,
    required this.tracking,
    required this.aspect,
    required this.overlay,
    this.onTapSensor,
  });

  final TrackingRepository tracking;

  /// Ekrandaki alanın genişlik / yükseklik oranı (1, 3/4, 9/16).
  final double aspect;
  final List<Widget> Function(FrameMapping map) overlay;
  final ValueChanged<Offset>? onTapSensor;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LayoutBuilder(builder: (context, box) {
          final t = tracking.tracker;
          final map = FrameMapping(box.biggest, t?.sensorAspect ?? 1);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onTapSensor == null ? null : (d) => onTapSensor!(map.toSensor(d.localPosition)),
            child: Stack(fit: StackFit.expand, children: [
              const ColoredBox(color: AppColors.scene),
              Positioned(
                left: map.origin.dx,
                top: map.origin.dy,
                width: map.drawn.width,
                height: map.drawn.height,
                child: _feed(),
              ),
              ...overlay(map),
            ]),
          );
        }),
      ),
    );
  }

  Widget _feed() {
    final cam = tracking.camera;
    if (cam != null && cam.value.isInitialized) return CameraPreview(cam);
    final sim = tracking.sim;
    if (sim != null) {
      return StreamBuilder(
        stream: sim.samples,
        builder: (_, _) => CustomPaint(painter: SimScenePainter(sim)),
      );
    }
    return const Center(child: Text('Kamera açılıyor…', style: TextStyle(color: AppColors.mid)));
  }
}

/// Simülatör sahnesi: zemin ızgarası, 1 m işaret, şarj istasyonu ve robot.
class SimScenePainter extends CustomPainter {
  SimScenePainter(this.sim);
  final SimTracker sim;

  @override
  void paint(Canvas c, Size s) {
    Offset at(Offset n) => Offset(n.dx * s.width, n.dy * s.height);
    final grid = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (var i = 1; i < 16; i++) {
      c.drawLine(Offset(s.width * i / 16, 0), Offset(s.width * i / 16, s.height), grid);
      c.drawLine(Offset(0, s.height * i / 16), Offset(s.width, s.height * i / 16), grid);
    }
    // 1 m zemin işareti
    final mark = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3;
    c.drawLine(at(SimTracker.markerP1), at(SimTracker.markerP2), mark);
    // şarj istasyonu
    final st = at(SimTracker.toFrame(SimTracker.stationM + const Offset(0, 0.12)));
    c.drawRect(Rect.fromCenter(center: st, width: s.width * 0.1, height: s.height * 0.035),
        Paint()..color = const Color(0xFF9E9E9E));
    // robot
    final p = sim.lastPose;
    if (p == null || !p.visible) return;
    final center = at(SimTracker.toFrame(Offset(p.xM, p.yM)));
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(p.headingDeg * math.pi / 180);
    final body = Rect.fromCenter(center: Offset.zero, width: s.width * 0.07, height: s.width * 0.05);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFFBDBDBD));
    c.drawCircle(Offset(0, -body.height * 0.15), body.width * 0.18, Paint()..color = const Color(0xFFE040FB)); // macenta işaret
    c.drawLine(Offset(0, -body.height / 2), Offset(0, -body.height / 2 - 8),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2);
    c.restore();
  }

  @override
  bool shouldRepaint(SimScenePainter o) => true;
}
