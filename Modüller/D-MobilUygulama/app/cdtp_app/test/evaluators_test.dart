import 'package:cdtp_robot_app/features/camera/domain/motion_sample.dart';
import 'package:cdtp_robot_app/features/connection/domain/robot_telemetry.dart';
import 'package:cdtp_robot_app/features/settings/domain/app_settings.dart';
import 'package:cdtp_robot_app/features/tasks/domain/evaluation.dart';
import 'package:cdtp_robot_app/features/tasks/domain/evaluators/task_evaluators.dart';
import 'package:cdtp_robot_app/features/tasks/domain/test_recording.dart';
import 'package:cdtp_robot_app/features/tasks/domain/test_task.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 10, 13, 12);
const _th = EvaluationThresholds();

/// 1 Hz sahte telemetri uretir. [at] her saniye icin degerleri belirler.
List<RobotTelemetry> _telemetry(
  int seconds, {
  double Function(int s)? tilt,
  bool Function(int s)? charging,
  bool Function(int s)? docked,
  RobotReportedState? Function(int s)? state,
  bool? Function(int s)? box,
  Set<int> skip = const {},
}) =>
    [
      for (var s = 0; s <= seconds; s++)
        if (!skip.contains(s))
          RobotTelemetry(
            receivedAt: _t0.add(Duration(milliseconds: 300 + s * 1000)),
            batteryPct: 80,
            tiltDeg: tilt?.call(s) ?? 1.0,
            charging: charging?.call(s) ?? false,
            docked: docked?.call(s),
            state: state?.call(s),
            boxPresent: box?.call(s),
          ),
    ];

TestRecording _rec(
  TestTask task,
  List<RobotTelemetry> telemetry, {
  int durationS = 31,
  TaskParams params = const TaskParams(),
  List<MotionSample> motion = const [],
}) =>
    TestRecording(
      testId: 'T-test',
      task: task,
      params: params,
      startedAt: _t0,
      endedAt: _t0.add(Duration(seconds: durationS)),
      telemetry: telemetry,
      motion: [...motion],
    );

CriterionResult _c(EvaluationResult r, String id) => r.criteria.firstWhere((c) => c.id == id);

void main() {
  group('Statik denge (A)', () {
    test('30 s dengede kalinca GECTI', () {
      final r = StaticBalanceEvaluator().evaluate(_rec(TestTask.staticBalance, _telemetry(31)), _th);
      expect(r.verdict, Verdict.passed);
      // Kamera yokken bilgi amacli kriter "veri yok" olur ama karari etkilemez.
      expect(_c(r, 'stationary').status, CriterionStatus.missing);
    });

    test('12. saniyede duserse KALDI', () {
      final rec = _rec(TestTask.staticBalance, _telemetry(31, tilt: (s) => s >= 12 ? 70 : 1));
      final r = StaticBalanceEvaluator().evaluate(rec, _th);
      expect(r.verdict, Verdict.failed);
      expect(_c(r, 'no_fall').status, CriterionStatus.fail);
    });

    test('3 s telemetri boslugu baglanti kriterini dusurur', () {
      final rec = _rec(TestTask.staticBalance, _telemetry(31, skip: {10, 11, 12}));
      final r = StaticBalanceEvaluator().evaluate(rec, _th);
      expect(_c(r, 'link_gap').status, CriterionStatus.fail);
      expect(r.verdict, Verdict.failed);
    });

    test('30 s dolunca otomatik biter', () {
      final rec = _rec(TestTask.staticBalance, _telemetry(31));
      rec.endedAt = null;
      final ev = StaticBalanceEvaluator();
      expect(ev.checkAutoStop(rec, _th, _t0.add(const Duration(seconds: 10))), isNull);
      expect(ev.checkAutoStop(rec, _th, _t0.add(const Duration(seconds: 31))), EndReason.completed);
    });
  });

  group('Sarj etme (C)', () {
    test('yerlesmeden 2 s sonra sarj -> GECTI', () {
      final tel = _telemetry(15, docked: (s) => s >= 8, charging: (s) => s >= 10);
      final r = ChargingEvaluator().evaluate(_rec(TestTask.charging, tel, durationS: 15), _th);
      expect(_c(r, 'charge_start').status, CriterionStatus.pass);
      expect(r.verdict, Verdict.passed);
    });

    test('yerlesmeden 7 s sonra sarj -> KALDI', () {
      final tel = _telemetry(20, docked: (s) => s >= 5, charging: (s) => s >= 12);
      final r = ChargingEvaluator().evaluate(_rec(TestTask.charging, tel, durationS: 20), _th);
      expect(r.verdict, Verdict.failed);
    });

    test('sarj hic baslamazsa KALDI', () {
      final tel = _telemetry(20, docked: (s) => s >= 5);
      final r = ChargingEvaluator().evaluate(_rec(TestTask.charging, tel, durationS: 20), _th);
      expect(r.verdict, Verdict.failed);
    });
  });

  group('Yonlendirme (B)', () {
    const params = TaskParams(expectedDirection: MotionDirection.forward);

    test('kamera verisi yoksa EKSIK VERI', () {
      final r = GuidanceEvaluator()
          .evaluate(_rec(TestTask.guidance, _telemetry(10), durationS: 10, params: params), _th);
      expect(r.verdict, Verdict.incomplete);
      expect(_c(r, 'direction').status, CriterionStatus.missing);
    });

    test('kamera 1 m ileri gorurse GECTI', () {
      final motion = [
        for (var i = 0; i <= 10; i++)
          MotionSample(
            time: _t0.add(Duration(seconds: i)),
            xM: 0,
            yM: i * 0.1,
            state: i < 10 ? CameraMotionState.moving : CameraMotionState.stationary,
            direction: i < 10 ? MotionDirection.forward : MotionDirection.none,
          ),
      ];
      final r = GuidanceEvaluator().evaluate(
        _rec(TestTask.guidance, _telemetry(10), durationS: 10, params: params, motion: motion),
        _th,
      );
      expect(_c(r, 'distance').status, CriterionStatus.pass);
      expect(r.verdict, Verdict.passed);
    });

    test('yanlis yon -> KALDI', () {
      final motion = [
        for (var i = 0; i <= 10; i++)
          MotionSample(
            time: _t0.add(Duration(seconds: i)),
            xM: 0,
            yM: -i * 0.1,
            direction: MotionDirection.backward,
          ),
      ];
      final r = GuidanceEvaluator().evaluate(
        _rec(TestTask.guidance, _telemetry(10), durationS: 10, params: params, motion: motion),
        _th,
      );
      expect(r.verdict, Verdict.failed);
    });
  });

  group('Butunlesik gorev (E)', () {
    test('kutu duserse KALDI', () {
      final tel = _telemetry(
        40,
        box: (s) => s < 20,
        docked: (s) => s >= 30,
        charging: (s) => s >= 32,
      );
      final r = IntegratedEvaluator().evaluate(_rec(TestTask.integrated, tel, durationS: 40), _th);
      expect(_c(r, 'box_kept').status, CriterionStatus.fail);
      expect(r.verdict, Verdict.failed);
    });

    test('telemetriyle hedefte bekleme olculur; kamera yoksa EKSIK VERI', () {
      final tel = _telemetry(
        40,
        box: (_) => true,
        state: (s) => switch (s) {
          < 6 => RobotReportedState.balancing,
          < 12 => RobotReportedState.moving,
          < 20 => RobotReportedState.balancing,
          < 30 => RobotReportedState.docking,
          _ => RobotReportedState.docked,
        },
        docked: (s) => s >= 30,
        charging: (s) => s >= 32,
      );
      final r = IntegratedEvaluator().evaluate(_rec(TestTask.integrated, tel, durationS: 40), _th);
      expect(_c(r, 'initial_balance').status, CriterionStatus.pass);
      expect(_c(r, 'target_wait').status, CriterionStatus.pass);
      expect(_c(r, 'charge_start').status, CriterionStatus.pass);
      expect(_c(r, 'box_kept').status, CriterionStatus.pass);
      // Mesafe sadece kameradan olculur.
      expect(_c(r, 'travel').status, CriterionStatus.missing);
      expect(r.verdict, Verdict.incomplete);
    });
  });
}
