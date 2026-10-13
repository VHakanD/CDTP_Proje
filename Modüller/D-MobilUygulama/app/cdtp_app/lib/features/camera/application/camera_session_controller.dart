import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/placeholder_motion_tracker.dart';
import '../data/video_storage.dart';
import '../domain/motion_tracker.dart';

/// Kullanilan hareket tespit yontemi.
/// Ekip yontemi sectiginde burada PlaceholderMotionTracker degistirilir.
final motionTrackerProvider = Provider<MotionTracker>((ref) {
  final tracker = PlaceholderMotionTracker();
  ref.onDispose(tracker.dispose);
  return tracker;
});

enum CameraStatus { idle, initializing, ready, unavailable, error }

@immutable
class CameraViewState {
  const CameraViewState({
    this.status = CameraStatus.idle,
    this.controller,
    this.isRecording = false,
    this.message,
  });

  final CameraStatus status;
  final CameraController? controller;
  final bool isRecording;
  final String? message;

  CameraViewState copyWith({
    CameraStatus? status,
    CameraController? controller,
    bool? isRecording,
    String? message,
  }) =>
      CameraViewState(
        status: status ?? this.status,
        controller: controller ?? this.controller,
        isRecording: isRecording ?? this.isRecording,
        message: message ?? this.message,
      );
}

/// Telefon kamerasini yonetir: acma, onizleme, test videosu kaydi.
///
/// Sartname 5.2: "Testi Baslat" aninda kamera kaydi baslar; sonuc video ile saklanir.
class CameraSessionController extends Notifier<CameraViewState> {
  @override
  CameraViewState build() {
    ref.onDispose(() => state.controller?.dispose());
    return const CameraViewState();
  }

  /// Arka kamerayi acar. Zaten aciksa bir sey yapmaz.
  Future<void> initialize() async {
    if (state.status == CameraStatus.ready || state.status == CameraStatus.initializing) return;
    state = const CameraViewState(status: CameraStatus.initializing);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = const CameraViewState(status: CameraStatus.unavailable, message: 'Kamera bulunamadı');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      state = CameraViewState(status: CameraStatus.ready, controller: controller);
    } on CameraException catch (e) {
      state = CameraViewState(status: CameraStatus.error, message: '${e.code}: ${e.description ?? ''}');
    } catch (e) {
      state = CameraViewState(status: CameraStatus.error, message: e.toString());
    }
  }

  /// Video kaydini baslatir. [onFrame] verilirse kayit sirasinda kareler hareket
  /// tespitine iletilir (sadece tespit yontemi uygulandiginda gerekir).
  Future<bool> startRecording({void Function(CameraImage image)? onFrame}) async {
    final c = state.controller;
    if (c == null || !c.value.isInitialized || c.value.isRecordingVideo) return false;
    try {
      await c.startVideoRecording(onAvailable: onFrame);
      state = state.copyWith(isRecording: true);
      return true;
    } catch (e) {
      state = state.copyWith(message: 'Kayıt başlatılamadı: $e');
      return false;
    }
  }

  /// Kaydi durdurur, dosyayi kalici klasore tasir ve SHA-256 hesaplar.
  Future<RecordedVideo?> stopRecording(String testId) async {
    final c = state.controller;
    if (c == null || !c.value.isRecordingVideo) return null;
    try {
      final file = await c.stopVideoRecording();
      state = state.copyWith(isRecording: false);
      return await persistVideo(file, testId);
    } catch (e) {
      state = state.copyWith(isRecording: false, message: 'Kayıt kaydedilemedi: $e');
      return null;
    }
  }

  /// Kamerayi kapatir (test ekranindan cikinca pil tasarrufu).
  Future<void> release() async {
    final c = state.controller;
    state = const CameraViewState();
    await c?.dispose();
  }
}

final cameraSessionProvider =
    NotifierProvider<CameraSessionController, CameraViewState>(CameraSessionController.new);
