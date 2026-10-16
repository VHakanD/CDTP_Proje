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

  /// Açık takip kaynağı hangi bağlantı türü için kuruldu (simülatör mü).
  bool? _openedForSim;
  Future<void>? _opening;

  /// Zaten açıksa ve bağlantı türü değişmediyse hiçbir şey yapmaz. Simülatör ↔
  /// gerçek robot geçişinde eski kaynağı kapatıp yenisini kurar.
  Future<void> open() => _opening ??= _open().whenComplete(() => _opening = null);

  Future<void> _open() async {
    final wantSim = kIsWeb || _robot.isSimulator;
    if (tracker != null) {
      if (_openedForSim == wantSim) return;
      await _release();
    }
    error = null;
    MotionTracker? t;
    if (trackerFactory != null) {
      t = trackerFactory!();
    } else if (wantSim) {
      t = SimTracker(_robot.simPose);
    } else {
      try {
        final cams = await availableCameras();
        final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cams.first);
        final c = CameraController(back, ResolutionPreset.medium,
            enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
        await c.initialize();
        camera = c;
        t = ColorMarkerTracker(c, clock: _robot.now);
      } catch (e) {
        // Gerçek robotta sanal sahne robotu göremez; kaynak boş kalır, "Tekrar dene" gösterilir.
        error = 'Kamera açılamadı: $e. Kamera iznini kontrol edin.';
      }
    }
    if (t != null) {
      await t.start();
      tracker = t;
      _openedForSim = wantSim;
    }
    notifyListeners();
  }

  /// Hata sonrası: kaynağı kapatıp yeniden açar.
  Future<void> retry() async {
    await close();
    await open();
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

  /// Birden çok kez çağrılabilir (sonuç ekranı, sahne ekranının dispose'u, bağlantı kesme).
  Future<void> close() async {
    await _opening; // yarıda kalan açılışı bekle; yoksa kamera açık kalır
    await _release();
  }

  Future<void> _release() async {
    final t = tracker, c = camera;
    tracker = null;
    camera = null;
    _openedForSim = null;
    error = null;
    await t?.stop();
    await c?.dispose();
    notifyListeners();
  }
}
