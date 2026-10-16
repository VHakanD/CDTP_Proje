import '../../../domain/models/motion.dart';

/// Kameradan robot konumu üreten kaynak. Konumlar sensör karesinde 0..1 normalize,
/// telefonun dik (portrait) yönüne döndürülmüş hâldedir.
abstract class MotionTracker {
  String get name;

  /// Sensör karesinin (dik yönde) genişlik / yükseklik oranı.
  double get sensorAspect;

  Stream<TrackSample> get samples;
  Future<void> start();
  Future<void> stop();
}
