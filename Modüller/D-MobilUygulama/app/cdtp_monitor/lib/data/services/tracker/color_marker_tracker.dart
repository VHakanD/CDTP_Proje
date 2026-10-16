import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/motion.dart';
import 'color_marker.dart';
import 'motion_tracker.dart';

/// Gerçek kamera (Android): robotun üstündeki renkli işareti takip eder ve
/// test sırasında videoyu kaydeder. Kareler ~10 Hz işlenir.
class ColorMarkerTracker implements MotionTracker {
  ColorMarkerTracker(this.controller, {this.color = MarkerColor.magenta, Duration Function()? clock})
      : _clock = clock ?? _stopwatch();

  static const processEvery = Duration(milliseconds: 100);

  final CameraController controller;
  final MarkerColor color;
  final Duration Function() _clock;
  final _out = StreamController<TrackSample>.broadcast();
  Duration _lastProcessed = -processEvery;
  bool _streaming = false;

  @override
  String get name => 'Telefon kamerası · renk işareti';

  /// Sensör yatay çeker; telefon dik tutulduğunda en/boy ters döner.
  @override
  double get sensorAspect {
    final s = controller.value.previewSize;
    if (s == null || s.width == 0) return 3 / 4;
    final rotated = controller.description.sensorOrientation % 180 != 0;
    return rotated ? s.height / s.width : s.width / s.height;
  }

  @override
  Stream<TrackSample> get samples => _out.stream;

  @override
  Future<void> start() async {
    if (_streaming || kIsWeb) return;
    await controller.startImageStream(_onImage);
    _streaming = true;
  }

  @override
  Future<void> stop() async {
    if (!_streaming) return;
    _streaming = false;
    if (controller.value.isStreamingImages) await controller.stopImageStream();
  }

  /// Video kaydı başlarken kare akışı kayıt çağrısına taşınır.
  Future<void> startRecording() async {
    await stop();
    await controller.startVideoRecording(onAvailable: _onImage);
  }

  Future<String?> stopRecording() async {
    if (!controller.value.isRecordingVideo) return null;
    final file = await controller.stopVideoRecording();
    return file.path;
  }

  void _onImage(CameraImage img) {
    final t = _clock();
    if (t - _lastProcessed < processEvery || img.planes.length < 3) return;
    _lastProcessed = t;
    final frame = YuvFrame(
      width: img.width,
      height: img.height,
      y: img.planes[0].bytes,
      u: img.planes[1].bytes,
      v: img.planes[2].bytes,
      yRowStride: img.planes[0].bytesPerRow,
      uvRowStride: img.planes[1].bytesPerRow,
      uvPixelStride: img.planes[1].bytesPerPixel ?? 1,
    );
    final hit = findMarker(frame, color);
    _out.add(TrackSample(
      t: t,
      center: hit == null ? null : rotateToPortrait(hit.center, controller.description.sensorOrientation),
      confidence: hit?.confidence ?? 0,
    ));
  }

  static Duration Function() _stopwatch() {
    final sw = Stopwatch()..start();
    return () => sw.elapsed;
  }
}
