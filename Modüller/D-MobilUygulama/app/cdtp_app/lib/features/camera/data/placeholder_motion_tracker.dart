import 'dart:async';

import 'package:camera/camera.dart';

import '../domain/motion_sample.dart';
import '../domain/motion_tracker.dart';

/// Hareket tespiti henuz yokken kullanilan bos implementasyon.
///
/// Hicbir ornek uretmez. Boylece:
///  - Canli ekranda kamera kaynakli alanlar "—" gorunur,
///  - Degerlendirmede kamera gerektiren kriterler "Veri yok" olur,
///  - Video kaydi ve telemetri tabanli kriterler normal calisir.
class PlaceholderMotionTracker implements MotionTracker {
  final _ctrl = StreamController<MotionSample>.broadcast();

  @override
  String get name => 'Yapılandırılmadı';

  @override
  bool get isImplemented => false;

  @override
  bool get needsFrames => false;

  @override
  Stream<MotionSample> get samples => _ctrl.stream;

  @override
  Future<void> start() async {}

  @override
  void processFrame(CameraImage image) {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() => _ctrl.close();
}
