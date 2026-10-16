import 'dart:ui';

import 'package:cdtp_monitor/domain/models/criterion.dart';
import 'package:cdtp_monitor/domain/models/motion.dart';
import 'package:cdtp_monitor/domain/models/scene_setup.dart';
import 'package:cdtp_monitor/domain/models/telemetry.dart';
import 'package:cdtp_monitor/domain/models/test_task.dart';
import 'package:cdtp_monitor/domain/use_cases/task_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

const scaled = SceneSetup(p1: Offset(0.3, 0.2), p2: Offset(0.55, 0.2));
const zoneScene = SceneSetup(
    p1: Offset(0.3, 0.2), p2: Offset(0.55, 0.2), targetZone: Rect.fromLTRB(0.4, 0.2, 0.6, 0.4));

MotionSnapshot snap({
  MotionState state = MotionState.staticBalance,
  Heading heading = Heading.stopped,
  double? d,
  Offset? at = const Offset(0.5, 0.8),
  TrackQuality q = TrackQuality.visible,
}) =>
    MotionSnapshot(state: state, heading: heading, distanceM: d, quality: q, confidence: 0.9, center: at, trail: const []);

Telemetry tel({double tilt = 1, bool charging = false, bool? docked, bool? box, String? state}) =>
    Telemetry(batteryPct: 70, tiltDeg: tilt, charging: charging, docked: docked, boxPresent: box, state: state);

Duration ms(int v) => Duration(milliseconds: v);

/// [secs] saniye boyunca 10 Hz statik örnek + 1 Hz telemetri.
void feedStatic(TaskRun r, int fromMs, int toMs, {Offset at = const Offset(0.5, 0.8), Telemetry Function()? t}) {
  for (var x = fromMs; x <= toMs; x += 100) {
    r.onSnapshot(ms(x), snap(at: at));
    if (x % 1000 == 0) r.onTelemetry(ms(x), (t ?? tel)());
  }
}

Criterion named(List<Criterion> c, String name) => c.firstWhere((x) => x.name == name);

void main() {
  group('A · Statik Denge', () {
    test('a_passes_30s_static', () {
      final r = TaskRun(task: TaskKind.staticBalance, scene: scaled);
      feedStatic(r, 0, 30000);
      expect(r.autoEnd, isTrue);
      final c = r.evaluate(gapMax: ms(1000));
      expect(TaskRun.verdictOf(c), Verdict.pass);
    });

    test('a_fails_on_fall', () {
      final r = TaskRun(task: TaskKind.staticBalance, scene: scaled);
      feedStatic(r, 0, 12000);
      r.onTelemetry(ms(12100), tel(tilt: 60, state: 'fallen'));
      expect(r.autoEnd, isTrue);
      final c = r.evaluate(gapMax: ms(1000));
      expect(named(c, 'Denge').result, CriterionResult.fail);
      expect(named(c, 'Süre').result, CriterionResult.fail);
      expect(TaskRun.verdictOf(c), Verdict.fail);
    });
  });

  group('B · Yönlendirme', () {
    TaskRun driveB(Heading expected, Heading actual, double meters) {
      final r = TaskRun(task: TaskKind.guidance, scene: scaled, expected: expected);
      for (var x = 0; x <= 4000; x += 100) {
        r.onSnapshot(ms(x), snap(state: MotionState.moving, heading: actual, d: meters * x / 4000));
        if (x % 1000 == 0) r.onTelemetry(ms(x), tel());
      }
      for (var x = 4100; x <= 6500; x += 100) {
        r.onSnapshot(ms(x), snap(d: meters));
        if (x % 1000 == 0) r.onTelemetry(ms(x), tel());
      }
      return r;
    }

    test('b_passes_forward_0_97m', () {
      final r = driveB(Heading.forward, Heading.forward, 0.97);
      expect(r.autoEnd, isTrue);
      expect(TaskRun.verdictOf(r.evaluate(gapMax: ms(1000))), Verdict.pass);
    });

    test('b_wrong_direction_fails', () {
      final c = driveB(Heading.forward, Heading.left, 0.97).evaluate(gapMax: ms(1000));
      expect(named(c, 'Yön').result, CriterionResult.fail);
    });

    test('b_too_far_fails', () {
      final c = driveB(Heading.forward, Heading.forward, 1.4).evaluate(gapMax: ms(1000));
      expect(named(c, 'Mesafe').result, CriterionResult.fail);
    });

    test('b_without_scale_fails', () {
      final r = TaskRun(task: TaskKind.guidance, scene: const SceneSetup(), expected: Heading.forward);
      for (var x = 0; x <= 3000; x += 100) {
        r.onSnapshot(ms(x), snap(state: MotionState.moving, heading: Heading.forward, d: null));
        if (x % 1000 == 0) r.onTelemetry(ms(x), tel());
      }
      final c = r.evaluate(gapMax: ms(1000));
      expect(named(c, 'Mesafe').result, CriterionResult.fail);
      expect(named(c, 'Mesafe').reason, contains('ölçülemedi'));
      expect(TaskRun.verdictOf(c), Verdict.fail);
    });
  });

  group('C · Şarj', () {
    test('c_charging_within_5s_passes', () {
      final r = TaskRun(task: TaskKind.charging, scene: zoneScene);
      feedStatic(r, 0, 2000);
      r.onTelemetry(ms(2500), tel(docked: true));
      r.onTelemetry(ms(4500), tel(docked: true, charging: true));
      expect(r.autoEnd, isTrue);
      expect(TaskRun.verdictOf(r.evaluate(gapMax: ms(1000))), Verdict.pass);
    });

    test('c_charging_after_6s_fails', () {
      final r = TaskRun(task: TaskKind.charging, scene: zoneScene);
      r.onTelemetry(ms(1000), tel(docked: true));
      r.onTelemetry(ms(7000), tel(docked: true, charging: true));
      final c = r.evaluate(gapMax: ms(1000));
      expect(named(c, 'Şarj başlangıcı').result, CriterionResult.fail);
    });

    test('c_dock_from_camera_when_robot_silent', () {
      final r = TaskRun(task: TaskKind.charging, scene: zoneScene);
      feedStatic(r, 0, 1500, at: const Offset(0.5, 0.3)); // hedef bölgede durağan
      r.onTelemetry(ms(3000), tel(charging: true));
      expect(named(r.evaluate(gapMax: ms(1000)), 'Yerleşme').result, CriterionResult.pass);
    });
  });

  group('E · Bütünleşik', () {
    test('e_passes_full_chain', () {
      final r = TaskRun(task: TaskKind.integrated, scene: zoneScene);
      feedStatic(r, 0, 6000, at: const Offset(0.5, 0.3), t: () => tel(box: true));
      r.onTelemetry(ms(6500), tel(box: true, docked: true, charging: true));
      expect(r.autoEnd, isTrue);
      expect(TaskRun.verdictOf(r.evaluate(gapMax: ms(1000))), Verdict.pass);
    });

    test('e_box_drop_fails', () {
      final r = TaskRun(task: TaskKind.integrated, scene: zoneScene);
      feedStatic(r, 0, 6000, at: const Offset(0.5, 0.3), t: () => tel(box: true));
      r.onTelemetry(ms(6200), tel(box: false));
      r.onTelemetry(ms(6500), tel(box: false, charging: true));
      expect(named(r.evaluate(gapMax: ms(1000)), 'Yük durumu').result, CriterionResult.fail);
    });
  });

  test('gap_over_2s_fails', () {
    final r = TaskRun(task: TaskKind.staticBalance, scene: scaled);
    feedStatic(r, 0, 30000);
    final c = r.evaluate(gapMax: ms(2400));
    expect(named(c, 'Bağlantı').result, CriterionResult.fail);
    expect(TaskRun.verdictOf(c), Verdict.fail);
  });
}
