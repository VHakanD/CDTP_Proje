import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Kameradan cikarilan hareket durumu (sartname 5.2: hareket ediyor, donuyor,
/// statik denge, toparlanma).
enum CameraMotionState {
  unknown('—'),
  stationary('Statik denge'),
  moving('Hareket ediyor'),
  turning('Dönüyor'),
  recovering('Toparlanıyor');

  const CameraMotionState(this.label);
  final String label;
}

/// Kameradan cikarilan hareket yonu (ileri, geri, sag, sol).
enum MotionDirection {
  none('—'),
  forward('İleri'),
  backward('Geri'),
  left('Sol'),
  right('Sağ');

  const MotionDirection(this.label);
  final String label;
}

/// Kamera izleyicisinin tek bir kare (veya kisa pencere) icin urettigi sonuc.
///
/// Konumlar zemin duzleminde, kalibrasyon sonrasi metre cinsindendir.
/// Baslangic noktasi (0,0) test baslangicindaki robot konumudur.
@immutable
class MotionSample {
  const MotionSample({
    required this.time,
    this.xM,
    this.yM,
    this.headingDeg,
    this.state = CameraMotionState.unknown,
    this.direction = MotionDirection.none,
    this.atStation,
    this.boxVisible,
    this.confidence = 0,
  });

  final DateTime time;
  final double? xM;
  final double? yM;
  final double? headingDeg;
  final CameraMotionState state;
  final MotionDirection direction;

  /// Robot sarj istasyonunun yerlesme bolgesinde mi (kamera ile).
  final bool? atStation;

  /// Ilac kutusu robot uzerinde gorunuyor mu (kamera ile).
  final bool? boxVisible;

  /// 0..1 arasi tespit guveni.
  final double confidence;

  bool get hasPosition => xM != null && yM != null;

  Map<String, Object?> toJson() => {
        't': time.toUtc().toIso8601String(),
        if (xM != null) 'x_m': xM,
        if (yM != null) 'y_m': yM,
        if (headingDeg != null) 'heading_deg': headingDeg,
        'state': state.name,
        'direction': direction.name,
        if (atStation != null) 'at_station': atStation,
        if (boxVisible != null) 'box_visible': boxVisible,
        'confidence': confidence,
      };

  factory MotionSample.fromJson(Map<String, Object?> j) => MotionSample(
        time: DateTime.parse(j['t']! as String),
        xM: (j['x_m'] as num?)?.toDouble(),
        yM: (j['y_m'] as num?)?.toDouble(),
        headingDeg: (j['heading_deg'] as num?)?.toDouble(),
        state: CameraMotionState.values.asNameMap()[j['state']] ?? CameraMotionState.unknown,
        direction: MotionDirection.values.asNameMap()[j['direction']] ?? MotionDirection.none,
        atStation: j['at_station'] as bool?,
        boxVisible: j['box_visible'] as bool?,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
      );
}

/// Bir test boyunca toplanan kamera orneklerinin ozeti.
/// Degerlendiriciler mesafe, yon ve son konumu buradan okur.
/// Ornek yoksa tum alanlar null olur ve ilgili kriter "veri yok" sayilir.
class MotionTrackSummary {
  MotionTrackSummary(List<MotionSample> samples)
      : _positioned = samples.where((s) => s.hasPosition).toList(),
        _all = samples;

  final List<MotionSample> _all;
  final List<MotionSample> _positioned;

  bool get hasData => _positioned.length >= 2;

  /// Baslangic ile son konum arasindaki duz cizgi mesafesi.
  double? get netDistanceM {
    if (!hasData) return null;
    final a = _positioned.first, b = _positioned.last;
    return _dist(a, b);
  }

  /// Baslangictan en fazla uzaklasma (statik denge kontrolu icin).
  double? get maxDisplacementM {
    if (!hasData) return null;
    final a = _positioned.first;
    return _positioned.map((s) => _dist(a, s)).reduce(math.max);
  }

  /// En cok gorulen (hareketli) yon.
  MotionDirection? get dominantDirection {
    final counts = <MotionDirection, int>{};
    for (final s in _all) {
      if (s.direction != MotionDirection.none) {
        counts[s.direction] = (counts[s.direction] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  MotionSample? get last => _all.isEmpty ? null : _all.last;

  /// Sondan geriye dogru kesintisiz "stationary" suresi (hedefte bekleme).
  Duration? get trailingStationary {
    if (_all.isEmpty) return null;
    final end = _all.last.time;
    DateTime? start;
    for (final s in _all.reversed) {
      if (s.state != CameraMotionState.stationary) break;
      start = s.time;
    }
    return start == null ? Duration.zero : end.difference(start);
  }

  /// Kamera kutuyu hic kaybetti mi (null = kamera bu bilgiyi vermiyor).
  bool? get boxEverLost {
    final known = _all.where((s) => s.boxVisible != null);
    if (known.isEmpty) return null;
    return known.any((s) => s.boxVisible == false);
  }

  static double _dist(MotionSample a, MotionSample b) {
    final dx = b.xM! - a.xM!, dy = b.yM! - a.yM!;
    return math.sqrt(dx * dx + dy * dy);
  }
}
