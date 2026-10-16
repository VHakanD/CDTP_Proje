import 'dart:ui' show Offset;

import '../models/motion.dart';
import '../models/scene_setup.dart';
import '../models/telemetry.dart';

/// Takip örneklerinden hareket durumu, yön ve mesafe çıkarır (HUD + değerlendirme).
///
/// Kurallar (plan, Task 3):
/// - Hız 0,5 s'lik pencereden hesaplanır; eşik 0,05 m/s (ölçek yoksa 0,02 birim/s).
/// - Yön, hız vektörünün robotun önü ([SceneSetup.frontAxis]) ve ona dik eksen
///   üzerindeki izdüşümlerinden büyük olanıdır.
/// - Güven < 0,60 → zayıf; 1 s görünür örnek yoksa → kayboldu.
/// - Kayıp aralıktaki sıçrama mesafeye eklenmez.
class MotionAnalyzer {
  MotionAnalyzer(this.scene);

  static const window = Duration(milliseconds: 500);
  static const lostAfter = Duration(seconds: 1);
  static const weakBelow = 0.60;
  static const moveThresholdMps = 0.05;
  static const moveThresholdUnits = 0.02;
  static const minStepM = 0.01;
  static const recoverTiltDeg = 8.0;
  static const _maxTrail = 400;

  final SceneSetup scene;

  final _recent = <(Duration, Offset)>[]; // görünür örnekler (iso birim)
  final _trail = <Offset>[];
  Offset? _anchorIso;
  Duration? _lastSeen;
  double _travelUnits = 0;
  MotionSnapshot _last = MotionSnapshot.initial;

  MotionSnapshot get current => _last;

  /// Örnek gelmese de zamanı ilerletir (ör. kayıp tespiti için 4 Hz çağrılır).
  MotionSnapshot tick(Duration now, {Telemetry? telemetry}) =>
      add(TrackSample(t: now, center: null, confidence: 0), telemetry: telemetry);

  MotionSnapshot add(TrackSample s, {Telemetry? telemetry}) {
    final c = s.center;
    if (c != null) {
      final p = scene.iso(c);
      final gapOk = _lastSeen != null && s.t - _lastSeen! < lostAfter;
      if (_anchorIso != null && gapOk) {
        final step = (p - _anchorIso!).distance;
        if (step >= _minStepUnits) {
          _travelUnits += step;
          _anchorIso = p;
        }
      } else {
        _anchorIso = p; // ilk görüş ya da kayıptan dönüş: sıçramayı sayma
      }
      _lastSeen = s.t;
      _recent.add((s.t, p));
      if (_trail.isEmpty || (_trail.last - c).distance > 0.004) {
        _trail.add(c);
        if (_trail.length > _maxTrail) _trail.removeAt(0);
      }
    }
    _recent.removeWhere((e) => s.t - e.$1 > window);
    return _last = _snapshot(s.t, s.confidence, c, telemetry);
  }

  double get _minStepUnits {
    final upm = scene.unitsPerMeter;
    return upm == null ? 0.005 : minStepM * upm;
  }

  MotionSnapshot _snapshot(Duration now, double conf, Offset? center, Telemetry? t) {
    final lost = _lastSeen == null || now - _lastSeen! >= lostAfter;
    final quality = lost
        ? TrackQuality.lost
        : (center == null || conf < weakBelow)
            ? TrackQuality.weak
            : TrackQuality.visible;

    final v = _velocity();
    final upm = scene.unitsPerMeter;
    final speed = v.distance;
    final moving = !lost &&
        (upm != null ? speed / upm >= moveThresholdMps : speed >= moveThresholdUnits);

    final MotionState state;
    if (t != null && (t.tiltDeg.abs() > recoverTiltDeg || t.state == 'recovering')) {
      state = MotionState.recovering;
    } else if (t?.state == 'turning') {
      state = MotionState.turning;
    } else if (moving) {
      state = MotionState.moving;
    } else {
      state = MotionState.staticBalance;
    }

    Heading heading = Heading.stopped;
    if (moving) {
      heading = _classify(v);
    } else if (state == MotionState.turning) {
      heading = switch (t?.lastCmd) {
        'left' => Heading.left,
        'right' => Heading.right,
        _ => Heading.stopped,
      };
    }

    return MotionSnapshot(
      state: state,
      heading: heading,
      distanceM: upm == null ? null : _travelUnits / upm,
      quality: quality,
      confidence: lost ? 0 : conf,
      center: lost ? null : (center ?? _last.center),
      trail: List.unmodifiable(_trail),
    );
  }

  /// Penceredeki ilk ve son görünür örnekten hız (iso birim / s).
  Offset _velocity() {
    if (_recent.length < 2) return Offset.zero;
    final (t0, p0) = _recent.first;
    final (t1, p1) = _recent.last;
    final dt = (t1 - t0).inMicroseconds / 1e6;
    if (dt <= 0) return Offset.zero;
    return (p1 - p0) / dt;
  }

  Heading _classify(Offset v) {
    var f = scene.iso(scene.frontAxis);
    final n = f.distance;
    if (n == 0) return Heading.stopped;
    f = f / n;
    final side = Offset(-f.dy, f.dx); // ön yukarıysa sağ +x
    final along = v.dx * f.dx + v.dy * f.dy;
    final lateral = v.dx * side.dx + v.dy * side.dy;
    if (along.abs() >= lateral.abs()) {
      return along > 0 ? Heading.forward : Heading.backward;
    }
    return lateral > 0 ? Heading.right : Heading.left;
  }
}
