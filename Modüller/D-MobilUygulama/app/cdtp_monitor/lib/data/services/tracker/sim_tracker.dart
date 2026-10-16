import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import '../../../domain/models/motion.dart';
import '../../../domain/models/telemetry.dart';
import 'motion_tracker.dart';

/// Simülatörün sanal kamerası. Robotun metre cinsinden konumunu (sim_pose)
/// kare içi normalize konuma çevirir. Gerçek kamerada robotu bulan kod
/// ([ColorMarkerTracker]) ile aynı arayüzü sunar.
class SimTracker implements MotionTracker {
  SimTracker(this._poses, {math.Random? random}) : _rnd = random ?? math.Random(7);

  /// Sanal kamera: robot başlangıçta (0,5; 0,8), 1 m = 0,25 birim, ileri = yukarı.
  static const origin = Offset(0.5, 0.8);
  static const unitsPerMeter = 0.25;

  /// Sahnedeki 1 m'lik zemin işareti (kalibrasyon için).
  static const markerP1 = Offset(0.25, 0.12);
  static const markerP2 = Offset(0.5, 0.12);

  /// Şarj istasyonu y = 1,2 m'de; hedef / şarj bölgesi.
  static const stationM = Offset(0, 1.2);
  static final targetZone = Rect.fromCenter(center: toFrame(stationM), width: 0.16, height: 0.12);

  static Offset toFrame(Offset meters) =>
      Offset(origin.dx + meters.dx * unitsPerMeter, origin.dy - meters.dy * unitsPerMeter);

  final Stream<(Duration, SimPose)> _poses;
  final math.Random _rnd;
  final _out = StreamController<TrackSample>.broadcast();
  StreamSubscription<(Duration, SimPose)>? _sub;

  /// Son konum ve yön (sanal sahneyi çizmek için).
  SimPose? lastPose;

  @override
  String get name => 'Simülatör kamerası';

  @override
  double get sensorAspect => 1;

  @override
  Stream<TrackSample> get samples => _out.stream;

  @override
  Future<void> start() async {
    _sub ??= _poses.listen((e) {
      final (t, p) = e;
      lastPose = p;
      final jitter = Offset(_rnd.nextDouble() - 0.5, _rnd.nextDouble() - 0.5) * 0.002;
      _out.add(TrackSample(
        t: t,
        center: p.visible ? toFrame(Offset(p.xM, p.yM)) + jitter : null,
        confidence: p.visible ? 0.9 + _rnd.nextDouble() * 0.08 : 0,
      ));
    });
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
