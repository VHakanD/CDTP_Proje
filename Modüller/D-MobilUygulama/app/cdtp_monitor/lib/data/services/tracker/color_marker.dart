import 'dart:typed_data';
import 'dart:ui' show Offset;

/// YUV420 kare (Android kamera akışı). Testlerde elle üretilebilir.
class YuvFrame {
  const YuvFrame({
    required this.width,
    required this.height,
    required this.y,
    required this.u,
    required this.v,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
  });

  final int width;
  final int height;
  final Uint8List y;
  final Uint8List u;
  final Uint8List v;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;
}

/// Robotun üstüne yapıştırılan renkli işaret. Varsayılan macenta: U ve V yüksek.
class MarkerColor {
  const MarkerColor({required this.uMin, required this.uMax, required this.vMin, required this.vMax, this.yMin = 40});

  static const magenta = MarkerColor(uMin: 150, uMax: 255, vMin: 150, vMax: 255);
  static const green = MarkerColor(uMin: 0, uMax: 110, vMin: 0, vMax: 110, yMin: 60);

  final int uMin, uMax, vMin, vMax, yMin;

  bool matches(int y, int u, int v) =>
      y >= yMin && u >= uMin && u <= uMax && v >= vMin && v <= vMax;
}

class MarkerHit {
  const MarkerHit(this.center, this.confidence);

  /// Sensör karesinde 0..1 (döndürülmemiş).
  final Offset center;
  final double confidence;
}

/// İşareti arar: her [stride]. pikselde renk eşiği, eşleşenlerin ağırlık merkezi.
/// Güven = eşleşen oran / [expectedFraction] (en fazla 1). Bulamazsa `null`.
MarkerHit? findMarker(
  YuvFrame f,
  MarkerColor color, {
  int stride = 4,
  double expectedFraction = 0.004,
  int minHits = 6,
}) {
  var hits = 0, sx = 0, sy = 0, total = 0;
  for (var py = 0; py < f.height; py += stride) {
    final uvRow = (py >> 1) * f.uvRowStride;
    final yRow = py * f.yRowStride;
    for (var px = 0; px < f.width; px += stride) {
      total++;
      final uvi = uvRow + (px >> 1) * f.uvPixelStride;
      if (color.matches(f.y[yRow + px], f.u[uvi], f.v[uvi])) {
        hits++;
        sx += px;
        sy += py;
      }
    }
  }
  if (hits < minHits || total == 0) return null;
  final conf = (hits / total / expectedFraction).clamp(0.0, 1.0);
  return MarkerHit(Offset(sx / hits / f.width, sy / hits / f.height), conf);
}

/// Sensör karesindeki konumu telefonun dik ekranına döndürür.
/// [sensorOrientation] Android arka kamerada çoğunlukla 90'dır.
Offset rotateToPortrait(Offset p, int sensorOrientation) => switch (sensorOrientation % 360) {
      90 => Offset(1 - p.dy, p.dx),
      180 => Offset(1 - p.dx, 1 - p.dy),
      270 => Offset(p.dy, 1 - p.dx),
      _ => p,
    };
