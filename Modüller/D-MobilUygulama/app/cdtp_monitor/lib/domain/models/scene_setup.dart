import 'dart:ui' show Offset, Rect;

/// Sahne hazırlama (wireframe 04) sonucu.
///
/// Tüm konumlar kamera *sensör karesinde* 0..1 normalizedir; ekrandaki
/// 1:1 / 4:3 / 9:16 kırpması bunları etkilemez. Mesafe hesabı için x ekseni
/// [sensorAspect] ile çarpılarak iki eksen aynı birime getirilir ([iso]).
class SceneSetup {
  const SceneSetup({
    this.sensorAspect = 1.0,
    this.p1,
    this.p2,
    this.markerLengthM = 1.0,
    this.start,
    this.frontAxis = const Offset(0, -1),
    this.targetZone,
    this.phoneFixed = false,
  });

  /// Sensör karesinin genişlik / yükseklik oranı.
  final double sensorAspect;
  final Offset? p1;
  final Offset? p2;

  /// P1–P2 arasındaki gerçek uzunluk (m).
  final double markerLengthM;
  final Offset? start;

  /// Görüntüde robotun "önü" (birim vektör). Varsayılan: kameradan uzağa (yukarı).
  final Offset frontAxis;
  final Rect? targetZone;
  final bool phoneFixed;

  /// Normalize birim başına metre ölçeği; P1/P2 yoksa `null`.
  double? get unitsPerMeter {
    if (p1 == null || p2 == null || markerLengthM <= 0) return null;
    final d = (iso(p2!) - iso(p1!)).distance;
    return d > 0 ? d / markerLengthM : null;
  }

  bool get hasScale => unitsPerMeter != null;

  /// Normalize konumu iki ekseni eşit ölçekli birime çevirir.
  Offset iso(Offset o) => Offset(o.dx * sensorAspect, o.dy);

  SceneSetup copyWith({
    double? sensorAspect,
    Offset? p1,
    Offset? p2,
    double? markerLengthM,
    Offset? start,
    Offset? frontAxis,
    Rect? targetZone,
    bool? phoneFixed,
  }) =>
      SceneSetup(
        sensorAspect: sensorAspect ?? this.sensorAspect,
        p1: p1 ?? this.p1,
        p2: p2 ?? this.p2,
        markerLengthM: markerLengthM ?? this.markerLengthM,
        start: start ?? this.start,
        frontAxis: frontAxis ?? this.frontAxis,
        targetZone: targetZone ?? this.targetZone,
        phoneFixed: phoneFixed ?? this.phoneFixed,
      );

  Map<String, dynamic> toJson() => {
        'sensor_aspect': sensorAspect,
        'p1': _o(p1),
        'p2': _o(p2),
        'marker_length_m': markerLengthM,
        'start': _o(start),
        'front_axis': _o(frontAxis),
        'target_zone': targetZone == null
            ? null
            : [targetZone!.left, targetZone!.top, targetZone!.right, targetZone!.bottom],
      };

  static List<double>? _o(Offset? o) => o == null ? null : [o.dx, o.dy];
}
