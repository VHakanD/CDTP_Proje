import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../services/tracker/color_marker_tracker.dart';
import '../services/tracker/motion_tracker.dart';
import '../services/tracker/sim_tracker.dart';
import 'robot_repository.dart';

/// Kamera kaynağını seçer ve sahne hazırlamadan sonuca kadar açık tutar.
///
/// - Web (Docker önizleme) ya da simülatör bağlantısı → [SimTracker] + sanal sahne.
/// - Android + gerçek robot → arka kamera + [ColorMarkerTracker] + video kaydı.
class TrackingRepository extends ChangeNotifier {
  TrackingRepository(this._robot, {this.trackerFactory});

  final RobotRepository _robot;

  /// Testlerde sahte takip kaynağı vermek için.
  final MotionTracker Function()? trackerFactory;
  MotionTracker? tracker;
  CameraController? camera;
  String? error;

  bool get isSim => tracker is SimTracker;
  SimTracker? get sim => tracker is SimTracker ? tracker as SimTracker : null;
  bool get ready => tracker != null;

  Future<void> open() async {
    if (tracker != null) return;
    error = null;
    if (trackerFactory != null) {
      tracker = trackerFactory!();
    } else if (kIsWeb || _robot.isSimulator) {
      tracker = SimTracker(_robot.simPose);
    } else {
      try {
        final cams = await availableCameras();
        final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cams.first);
        final c = CameraController(back, ResolutionPreset.medium,
            enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
        await c.initialize();
        camera = c;
        tracker = ColorMarkerTracker(c, clock: _robot.now);
      } catch (e) {
        error = 'Kamera açılamadı: $e. Kamera iznini kontrol edin.';
        tracker = SimTracker(_robot.simPose); // en azından simülatör konumu çalışsın
      }
    }
    await tracker!.start();
    notifyListeners();
  }

  Future<void> startRecording() async {
    final t = tracker;
    if (t is ColorMarkerTracker) await t.startRecording();
  }

  /// Video dosyasının yolu; simülatörde `null`.
  Future<String?> stopRecording() async {
    final t = tracker;
    if (t is ColorMarkerTracker) {
      final path = await t.stopRecording();
      await t.start();
      return path;
    }
    return null;
  }

  Future<void> close() async {
    await tracker?.stop();
    await camera?.dispose();
    tracker = null;
    camera = null;
    notifyListeners();
  }
}
