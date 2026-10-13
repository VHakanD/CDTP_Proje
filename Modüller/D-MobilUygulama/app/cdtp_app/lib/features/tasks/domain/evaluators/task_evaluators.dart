import '../../../../core/utils/formatters.dart';
import '../../../camera/domain/motion_sample.dart';
import '../../../connection/domain/robot_telemetry.dart';
import '../../../settings/domain/app_settings.dart';
import '../evaluation.dart';
import '../test_recording.dart';
import '../test_task.dart';
import 'common_criteria.dart';

/// Her gorev icin degerlendirme kurallari.
abstract class TaskEvaluator {
  /// Test bittikten sonra toplanan veriden kriterleri hesaplar.
  EvaluationResult evaluate(TestRecording rec, EvaluationThresholds th);

  /// Test surerken cagrilir; bitis kosulu olustuysa sebebini dondurur.
  EndReason? checkAutoStop(TestRecording rec, EvaluationThresholds th, DateTime now);

  static TaskEvaluator forTask(TestTask task) => switch (task) {
        TestTask.staticBalance => StaticBalanceEvaluator(),
        TestTask.guidance => GuidanceEvaluator(),
        TestTask.charging => ChargingEvaluator(),
        TestTask.integrated => IntegratedEvaluator(),
      };
}

double _secs(Duration d) => d.inMilliseconds / 1000;

// ---------------------------------------------------------------------------
// Modul A - Statik denge: 30 s dengede kalma
// ---------------------------------------------------------------------------
class StaticBalanceEvaluator implements TaskEvaluator {
  @override
  EvaluationResult evaluate(TestRecording rec, EvaluationThresholds th) {
    final end = rec.endedAt ?? DateTime.now();
    final fall = CommonCriteria.firstFall(rec, th);
    // Dengede kalinan sure: baslangictan ilk dusmeye (yoksa test sonuna) kadar.
    final balancedS = _secs((fall?.receivedAt ?? end).difference(rec.startedAt));
    final needed = th.staticBalanceSeconds - th.timeToleranceSeconds;

    final motion = MotionTrackSummary(rec.motion);
    final disp = motion.maxDisplacementM;

    return EvaluationResult(
      [
        CriterionResult(
          id: 'balance_duration',
          label: 'Dengede kalma süresi',
          expected: '≥ ${Fmt.seconds(th.staticBalanceSeconds)} (±${Fmt.seconds(th.timeToleranceSeconds)})',
          measured: Fmt.seconds(balancedS),
          status: balancedS >= needed ? CriterionStatus.pass : CriterionStatus.fail,
          source: DataSource.timer,
        ),
        CommonCriteria.noFall(rec, th),
        CommonCriteria.link(rec, th),
        // Kamera: robot yerinde mi durdu? (Tespit yontemi gelince zorunlu yapilabilir.)
        CriterionResult(
          id: 'stationary',
          label: 'Yerinde kalma (kamera)',
          expected: 'Yer değiştirme ≤ ${Fmt.meters(th.staticMaxDisplacementM)}',
          measured: Fmt.meters(disp),
          status: disp == null
              ? CriterionStatus.missing
              : (disp <= th.staticMaxDisplacementM ? CriterionStatus.pass : CriterionStatus.fail),
          source: DataSource.camera,
          required: false,
        ),
        CommonCriteria.rate(rec),
      ],
      metrics: {
        'balanced_s': balancedS,
        'max_tilt_deg': CommonCriteria.maxAbsTilt(rec.telemetry),
        'max_displacement_m': disp,
      },
    );
  }

  @override
  EndReason? checkAutoStop(TestRecording rec, EvaluationThresholds th, DateTime now) {
    if (CommonCriteria.firstFall(rec, th) != null) return EndReason.fallDetected;
    // 30 s dolunca 1 s pay birakip otomatik bitir.
    if (_secs(rec.elapsedAt(now)) >= th.staticBalanceSeconds + 1) return EndReason.completed;
    return null;
  }
}

// ---------------------------------------------------------------------------
// Modul B - Robot yonlendirmesi: dogru yon + 0,8-1,2 m (donuste ~90°)
// ---------------------------------------------------------------------------
class GuidanceEvaluator implements TaskEvaluator {
  @override
  EvaluationResult evaluate(TestRecording rec, EvaluationThresholds th) {
    final expectedDir = rec.params.expectedDirection;
    final motion = MotionTrackSummary(rec.motion);
    final dir = motion.dominantDirection;
    final isTurn = expectedDir == MotionDirection.left || expectedDir == MotionDirection.right;

    final criteria = <CriterionResult>[
      CriterionResult(
        id: 'direction',
        label: 'Hareket yönü (kamera)',
        expected: expectedDir?.label ?? Fmt.empty,
        measured: dir?.label ?? Fmt.empty,
        status: dir == null || expectedDir == null
            ? CriterionStatus.missing
            : (dir == expectedDir ? CriterionStatus.pass : CriterionStatus.fail),
        source: DataSource.camera,
      ),
    ];

    double? turnDeg;
    final dist = motion.netDistanceM;
    if (isTurn) {
      turnDeg = _headingChange(rec.motion);
      criteria.add(CriterionResult(
        id: 'turn_angle',
        label: 'Dönüş açısı (kamera)',
        expected: '${Fmt.degrees(th.turnTargetDeg)} ± ${Fmt.degrees(th.turnToleranceDeg)}',
        measured: Fmt.degrees(turnDeg),
        status: turnDeg == null
            ? CriterionStatus.missing
            : ((turnDeg.abs() - th.turnTargetDeg).abs() <= th.turnToleranceDeg
                ? CriterionStatus.pass
                : CriterionStatus.fail),
        source: DataSource.camera,
      ));
    } else {
      criteria.add(CriterionResult(
        id: 'distance',
        label: 'Kat edilen mesafe (kamera)',
        expected: '${Fmt.meters(th.distanceMinM)} – ${Fmt.meters(th.distanceMaxM)}',
        measured: Fmt.meters(dist),
        status: dist == null
            ? CriterionStatus.missing
            : (dist >= th.distanceMinM && dist <= th.distanceMaxM
                ? CriterionStatus.pass
                : CriterionStatus.fail),
        source: DataSource.camera,
      ));
    }

    // Bilgi: robotun eldivenden aldigini bildirdigi son komut.
    final cmds = rec.telemetry.map((t) => t.lastCommand).whereType<GloveCommand>().toList();
    final received = cmds.where((c) => c != GloveCommand.stop).lastOrNull;
    criteria
      ..add(CriterionResult(
        id: 'glove_echo',
        label: 'Robotun aldığı komut',
        expected: expectedDir == null ? Fmt.empty : _commandFor(expectedDir).label,
        measured: received?.label ?? Fmt.empty,
        status: received == null || expectedDir == null
            ? CriterionStatus.missing
            : (received == _commandFor(expectedDir) ? CriterionStatus.pass : CriterionStatus.fail),
        source: DataSource.telemetry,
        required: false,
      ))
      ..add(CommonCriteria.noFall(rec, th))
      ..add(CommonCriteria.link(rec, th))
      ..add(CommonCriteria.rate(rec));

    return EvaluationResult(criteria, metrics: {
      'expected_direction': expectedDir?.name,
      'detected_direction': dir?.name,
      'distance_m': dist,
      'turn_deg': turnDeg,
      'duration_s': _secs(rec.elapsedAt(DateTime.now())),
    });
  }

  static GloveCommand _commandFor(MotionDirection d) => switch (d) {
        MotionDirection.forward => GloveCommand.forward,
        MotionDirection.backward => GloveCommand.backward,
        MotionDirection.left => GloveCommand.left,
        MotionDirection.right => GloveCommand.right,
        MotionDirection.none => GloveCommand.stop,
      };

  /// Ilk ve son yon bilgisi arasindaki fark (derece, -180..180).
  static double? _headingChange(List<MotionSample> samples) {
    final h = samples.where((s) => s.headingDeg != null).toList();
    if (h.length < 2) return null;
    var d = h.last.headingDeg! - h.first.headingDeg!;
    while (d > 180) {
      d -= 360;
    }
    while (d < -180) {
      d += 360;
    }
    return d;
  }

  @override
  EndReason? checkAutoStop(TestRecording rec, EvaluationThresholds th, DateTime now) {
    if (CommonCriteria.firstFall(rec, th) != null) return EndReason.fallDetected;
    if (_secs(rec.elapsedAt(now)) >= th.guidanceTimeoutSeconds) return EndReason.timeout;
    // Kamera: robot hareket edip en az 3 s durduysa hareket tamamlanmistir.
    final m = MotionTrackSummary(rec.motion);
    final moved = (m.maxDisplacementM ?? 0) >= 0.2 || m.dominantDirection != null;
    if (moved && (m.trailingStationary ?? Duration.zero) >= const Duration(seconds: 3)) {
      return EndReason.completed;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Modul C - Sarj etme: yerlesmeden sonra 5 s icinde sarj baslar
// ---------------------------------------------------------------------------
class ChargingEvaluator implements TaskEvaluator {
  @override
  EvaluationResult evaluate(TestRecording rec, EvaluationThresholds th) {
    final ct = CommonCriteria.chargeTiming(rec);
    final atCharge = ct.chargeAt == null
        ? null
        : rec.telemetry.firstWhere((t) => t.receivedAt == ct.chargeAt);
    final before = rec.telemetry.where((t) => t.batteryPct != null).firstOrNull?.batteryPct;
    final after = rec.telemetry.where((t) => t.batteryPct != null).lastOrNull?.batteryPct;

    return EvaluationResult(
      [
        CommonCriteria.chargeStart(rec, th),
        // Bilgi: sarj anindaki egim (robotun istasyona yerlesme durumu).
        CriterionResult(
          id: 'dock_tilt',
          label: 'Yerleşmede eğim',
          expected: 'Kararlı (|eğim| < 10°)',
          measured: Fmt.degrees(atCharge?.tiltDeg),
          status: atCharge?.tiltDeg == null
              ? CriterionStatus.missing
              : (atCharge!.tiltDeg!.abs() < 10 ? CriterionStatus.pass : CriterionStatus.fail),
          source: DataSource.telemetry,
          required: false,
        ),
        // Bilgi: pil duzeyi sarj sirasinda dusmemeli.
        CriterionResult(
          id: 'battery_trend',
          label: 'Pil düzeyi',
          expected: 'Azalmıyor',
          measured: before == null ? Fmt.empty : '${Fmt.percent(before)} → ${Fmt.percent(after)}',
          status: before == null || after == null
              ? CriterionStatus.missing
              : (after >= before ? CriterionStatus.pass : CriterionStatus.fail),
          source: DataSource.telemetry,
          required: false,
        ),
        CommonCriteria.link(rec, th),
        CommonCriteria.rate(rec),
      ],
      metrics: {
        'dock_at': ct.dockAt?.toUtc().toIso8601String(),
        'charge_at': ct.chargeAt?.toUtc().toIso8601String(),
        'charge_delay_s': ct.delaySeconds,
        'battery_start_pct': before,
        'battery_end_pct': after,
      },
    );
  }

  @override
  EndReason? checkAutoStop(TestRecording rec, EvaluationThresholds th, DateTime now) {
    final ct = CommonCriteria.chargeTiming(rec);
    // Sarj tespit edildikten 2 s sonra bitir (gosterge kontrolu icin kisa pay).
    if (ct.chargeAt != null && now.difference(ct.chargeAt!) >= const Duration(seconds: 2)) {
      return EndReason.completed;
    }
    if (_secs(rec.elapsedAt(now)) >= th.chargingTimeoutSeconds) return EndReason.timeout;
    return null;
  }
}

// ---------------------------------------------------------------------------
// Modul E - Butunlesik gorev
// 5 s denge -> ~1 m hareket -> kutu dusmeden hedefte 5 s -> istasyon -> sarj
// ---------------------------------------------------------------------------
class IntegratedEvaluator implements TaskEvaluator {
  @override
  EvaluationResult evaluate(TestRecording rec, EvaluationThresholds th) {
    final motion = MotionTrackSummary(rec.motion);

    // 1) Baslangicta 5 s dengede bekleme (telemetri).
    final initialWindowEnd =
        rec.startedAt.add(Duration(milliseconds: (th.initialBalanceSeconds * 1000).round()));
    final initial = rec.telemetry.where((t) => t.receivedAt.isBefore(initialWindowEnd)).toList();
    final initialFall = initial.any((t) => CommonCriteria.isFall(t, th));
    final initialMoving = initial.any(
      (t) => t.state == RobotReportedState.moving || t.state == RobotReportedState.turning,
    );
    final hasInitialTilt = initial.any((t) => t.tiltDeg != null);
    final testLongEnough = _secs(rec.elapsedAt(DateTime.now())) >= th.initialBalanceSeconds;

    // 2) Kat edilen yol (kamera).
    final disp = motion.maxDisplacementM;

    // 3) Kutu durumu: once robot sensoru, yoksa kamera.
    final boxKnown = rec.telemetry.where((t) => t.boxPresent != null);
    bool? boxLost;
    DataSource boxSource = DataSource.telemetry;
    if (boxKnown.isNotEmpty) {
      boxLost = boxKnown.any((t) => t.boxPresent == false);
    } else {
      boxLost = motion.boxEverLost;
      boxSource = DataSource.camera;
    }

    // 4) Hedefte 5 s bekleme: kamera "stationary" veya robotun "balancing" bildirimi.
    final wait = _targetWait(rec);

    return EvaluationResult(
      [
        CriterionResult(
          id: 'initial_balance',
          label: 'Başlangıçta dengede bekleme',
          expected: '${Fmt.seconds(th.initialBalanceSeconds)} hareketsiz denge',
          measured: !hasInitialTilt
              ? Fmt.empty
              : (initialFall ? 'Düştü' : (initialMoving ? 'Erken hareket' : 'Sağlandı')),
          status: !hasInitialTilt || !testLongEnough
              ? CriterionStatus.missing
              : (!initialFall && !initialMoving ? CriterionStatus.pass : CriterionStatus.fail),
          source: DataSource.telemetry,
        ),
        CriterionResult(
          id: 'travel',
          label: 'Hedefe hareket (kamera)',
          expected: '≥ ${Fmt.meters(th.distanceMinM)}',
          measured: Fmt.meters(disp),
          status: disp == null
              ? CriterionStatus.missing
              : (disp >= th.distanceMinM ? CriterionStatus.pass : CriterionStatus.fail),
          source: DataSource.camera,
        ),
        CriterionResult(
          id: 'box_kept',
          label: 'İlaç kutusu taşındı',
          expected: 'Kutu düşmedi',
          measured: boxLost == null ? Fmt.empty : (boxLost ? 'Kutu düştü' : 'Kutu yerinde'),
          status: boxLost == null
              ? CriterionStatus.missing
              : (boxLost ? CriterionStatus.fail : CriterionStatus.pass),
          source: boxSource,
        ),
        CriterionResult(
          id: 'target_wait',
          label: 'Hedefte bekleme',
          expected: '≥ ${Fmt.seconds(th.targetWaitSeconds)}',
          measured: Fmt.seconds(wait.seconds),
          status: wait.seconds == null
              ? CriterionStatus.missing
              : (wait.seconds! >= th.targetWaitSeconds - 0.5
                  ? CriterionStatus.pass
                  : CriterionStatus.fail),
          source: wait.source,
        ),
        CommonCriteria.chargeStart(rec, th),
        CommonCriteria.noFall(rec, th),
        CommonCriteria.link(rec, th),
        CommonCriteria.rate(rec),
      ],
      metrics: {
        'travel_m': disp,
        'target_wait_s': wait.seconds,
        'box_lost': boxLost,
        'charge_delay_s': CommonCriteria.chargeTiming(rec).delaySeconds,
        'duration_s': _secs(rec.elapsedAt(DateTime.now())),
      },
    );
  }

  /// Ilk hareketten sonra, istasyona yonelmeden onceki en uzun duraklama.
  ({double? seconds, DataSource source}) _targetWait(TestRecording rec) {
    // Kamera verisi varsa onu kullan.
    if (rec.motion.any((m) => m.state != CameraMotionState.unknown)) {
      return (seconds: _longestRun(
        rec.motion.map((m) => (m.time, m.state)).toList(),
        isMoving: (s) => s == CameraMotionState.moving || s == CameraMotionState.turning,
        isStill: (s) => s == CameraMotionState.stationary,
      ), source: DataSource.camera);
    }
    // Yoksa robotun kendi durum bildirimini kullan.
    if (rec.telemetry.any((t) => t.state != null)) {
      return (seconds: _longestRun(
        rec.telemetry.map((t) => (t.receivedAt, t.state)).toList(),
        isMoving: (s) => s == RobotReportedState.moving || s == RobotReportedState.turning,
        isStill: (s) => s == RobotReportedState.balancing || s == RobotReportedState.idle,
      ), source: DataSource.telemetry);
    }
    return (seconds: null, source: DataSource.camera);
  }

  static double? _longestRun<S>(
    List<(DateTime, S)> seq, {
    required bool Function(S) isMoving,
    required bool Function(S) isStill,
  }) {
    var movedOnce = false;
    DateTime? runStart;
    double best = 0;
    for (final (time, s) in seq) {
      if (isMoving(s)) {
        movedOnce = true;
        runStart = null;
      } else if (movedOnce && isStill(s)) {
        runStart ??= time;
        final len = time.difference(runStart).inMilliseconds / 1000;
        if (len > best) best = len;
      } else {
        runStart = null;
      }
    }
    return movedOnce ? best : null;
  }

  @override
  EndReason? checkAutoStop(TestRecording rec, EvaluationThresholds th, DateTime now) {
    if (CommonCriteria.firstFall(rec, th) != null) return EndReason.fallDetected;
    final ct = CommonCriteria.chargeTiming(rec);
    if (ct.chargeAt != null && now.difference(ct.chargeAt!) >= const Duration(seconds: 2)) {
      return EndReason.completed;
    }
    if (_secs(rec.elapsedAt(now)) >= th.integratedTimeoutSeconds) return EndReason.timeout;
    return null;
  }
}
