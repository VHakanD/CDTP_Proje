import 'package:cdtp_monitor/domain/models/motion.dart';
import 'package:cdtp_monitor/domain/models/scene_setup.dart';
import 'package:cdtp_monitor/domain/models/telemetry.dart';
import 'package:cdtp_monitor/domain/use_cases/motion_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

/// 0,25 birim = 1 m (P1–P2 yatay 0,25).
const scaled = SceneSetup(p1: Offset(0.3, 0.2), p2: Offset(0.55, 0.2));

TrackSample s(int ms, double x, double y, [double conf = 0.95]) =>
    TrackSample(t: Duration(milliseconds: ms), center: Offset(x, y), confidence: conf);

/// [from]..[to] arasında 10 Hz doğrusal hareket.
MotionSnapshot drive(MotionAnalyzer a, Offset from, Offset to, int ms, {int startMs = 0}) {
  late MotionSnapshot last;
  final steps = ms ~/ 100;
  for (var i = 0; i <= steps; i++) {
    final p = Offset.lerp(from, to, i / steps)!;
    last = a.add(s(startMs + i * 100, p.dx, p.dy));
  }
  return last;
}

void main() {
  test('forward_motion_detected', () {
    final a = MotionAnalyzer(scaled);
    // 0,25 birim yukarı = 1 m ileri, 4 s'de (0,25 m/s)
    final m = drive(a, const Offset(0.5, 0.8), const Offset(0.5, 0.55), 4000);
    expect(m.heading, Heading.forward);
    expect(m.state, MotionState.moving);
    expect(m.distanceM, closeTo(1.0, 0.03));
  });

  test('backward_motion_detected', () {
    final m = drive(MotionAnalyzer(scaled), const Offset(0.5, 0.5), const Offset(0.5, 0.6), 2000);
    expect(m.heading, Heading.backward);
  });

  test('lateral_is_left_or_right', () {
    expect(drive(MotionAnalyzer(scaled), const Offset(0.4, 0.5), const Offset(0.5, 0.5), 2000).heading,
        Heading.right);
    expect(drive(MotionAnalyzer(scaled), const Offset(0.5, 0.5), const Offset(0.4, 0.5), 2000).heading,
        Heading.left);
  });

  test('stationary_is_static', () {
    final a = MotionAnalyzer(scaled);
    late MotionSnapshot m;
    for (var i = 0; i < 20; i++) {
      m = a.add(s(i * 100, 0.5 + (i.isEven ? 0.001 : -0.001), 0.5));
    }
    expect(m.state, MotionState.staticBalance);
    expect(m.heading, Heading.stopped);
    expect(m.distanceM, closeTo(0, 0.01));
  });

  test('low_confidence_is_weak', () {
    final a = MotionAnalyzer(scaled);
    a.add(s(0, 0.5, 0.5));
    expect(a.add(s(100, 0.5, 0.5, 0.45)).quality, TrackQuality.weak);
  });

  test('lost_after_one_second', () {
    final a = MotionAnalyzer(scaled);
    a.add(s(0, 0.5, 0.5));
    expect(a.tick(const Duration(milliseconds: 600)).quality, TrackQuality.weak);
    expect(a.tick(const Duration(milliseconds: 1000)).quality, TrackQuality.lost);
  });

  test('lost_samples_do_not_add_distance', () {
    final a = MotionAnalyzer(scaled);
    a.add(s(0, 0.5, 0.8));
    a.tick(const Duration(milliseconds: 1500)); // kayboldu
    // 2 s sonra çok uzakta yeniden görünür: sıçrama sayılmaz
    final m = a.add(s(2000, 0.5, 0.3));
    expect(m.distanceM, closeTo(0, 0.001));
  });

  test('no_scale_distance_null', () {
    final m = drive(MotionAnalyzer(const SceneSetup()), const Offset(0.5, 0.8), const Offset(0.5, 0.5), 2000);
    expect(m.distanceM, isNull);
    expect(m.heading, Heading.forward);
  });

  test('tilt_means_recovering', () {
    final a = MotionAnalyzer(scaled);
    const tel = Telemetry(batteryPct: 70, tiltDeg: 9.5, charging: false);
    expect(a.add(s(0, 0.5, 0.5), telemetry: tel).state, MotionState.recovering);
  });

  test('sensor_aspect_makes_axes_equal', () {
    // 16:9 sensör: x'te 0,1 birim, y'de 0,1*16/9 birime eşit uzunluk
    const wide = SceneSetup(sensorAspect: 16 / 9, p1: Offset(0.2, 0.5), p2: Offset(0.2 + 0.25 * 9 / 16, 0.5));
    expect(wide.unitsPerMeter, closeTo(0.25, 1e-9));
  });
}
