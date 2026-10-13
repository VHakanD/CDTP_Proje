import 'package:flutter/foundation.dart';

/// Piksel -> metre donusumu icin kamera kalibrasyonu.
///
/// DURUM: Yer tutucu. Tespit yontemi secildiginde doldurulacak.
/// Ornek yontem: telefon sabitlenir, robot zeminde bilinen 1 m arayla iki
/// noktaya konur, her noktada goruntudeki piksel konumu kaydedilir.
@immutable
class CameraCalibration {
  const CameraCalibration({this.metersPerPixel, this.referenceDistanceM, this.createdAt});

  final double? metersPerPixel;
  final double? referenceDistanceM;
  final DateTime? createdAt;

  bool get isCalibrated => metersPerPixel != null;

  Map<String, Object?> toJson() => {
        'meters_per_pixel': metersPerPixel,
        'reference_distance_m': referenceDistanceM,
        'created_at': createdAt?.toUtc().toIso8601String(),
      };
}
