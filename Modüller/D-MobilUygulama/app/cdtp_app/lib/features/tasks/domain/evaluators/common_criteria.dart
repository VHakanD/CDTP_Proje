import '../../../../core/utils/formatters.dart';
import '../../../connection/domain/robot_telemetry.dart';
import '../../../settings/domain/app_settings.dart';
import '../evaluation.dart';
import '../test_recording.dart';

/// Birden fazla gorevde kullanilan ortak kriterler.
class CommonCriteria {
  CommonCriteria._();

  /// Sartname 5.2: baglanti test boyunca 2 s'den fazla kopmamali.
  /// Test baslangici, her telemetri ve test bitisi arasindaki en uzun bosluk olculur.
  static CriterionResult link(TestRecording rec, EvaluationThresholds th) {
    final limit = th.maxLinkGapSeconds;
    if (rec.telemetry.isEmpty) {
      return CriterionResult(
        id: 'link_gap',
        label: 'Bağlantı sürekliliği',
        expected: 'Kopma ≤ ${Fmt.seconds(limit)}',
        measured: 'Telemetri alınmadı',
        status: CriterionStatus.fail,
        source: DataSource.link,
      );
    }
    final gap = maxGapSeconds(rec);
    return CriterionResult(
      id: 'link_gap',
      label: 'Bağlantı sürekliliği',
      expected: 'Kopma ≤ ${Fmt.seconds(limit)}',
      measured: 'En uzun boşluk ${Fmt.seconds(gap)}',
      status: gap <= limit ? CriterionStatus.pass : CriterionStatus.fail,
      source: DataSource.link,
    );
  }

  static double maxGapSeconds(TestRecording rec) {
    final times = <DateTime>[
      rec.startedAt,
      ...rec.telemetry.map((t) => t.receivedAt),
      rec.endedAt ?? DateTime.now(),
    ];
    var maxMs = 0;
    for (var i = 1; i < times.length; i++) {
      final ms = times[i].difference(times[i - 1]).inMilliseconds;
      if (ms > maxMs) maxMs = ms;
    }
    // Ilk paket test basladiktan hemen sonra gelmeyebilir; 1 Hz'de en fazla 1 s beklenir.
    return maxMs / 1000;
  }

  /// Bilgi amacli: olculen telemetri frekansi (beklenen ~1 Hz).
  static CriterionResult rate(TestRecording rec) {
    final hz = measuredHz(rec);
    return CriterionResult(
      id: 'telemetry_rate',
      label: 'Telemetri frekansı',
      expected: '≈ 1 Hz',
      measured: hz == null ? Fmt.empty : '${Fmt.number(hz, digits: 2)} Hz',
      status: hz == null
          ? CriterionStatus.missing
          : (hz >= 0.8 && hz <= 1.5 ? CriterionStatus.pass : CriterionStatus.fail),
      source: DataSource.telemetry,
      required: false,
    );
  }

  static double? measuredHz(TestRecording rec) {
    final t = rec.telemetry;
    if (t.length < 2) return null;
    final s = t.last.receivedAt.difference(t.first.receivedAt).inMilliseconds / 1000;
    return s <= 0 ? null : (t.length - 1) / s;
  }

  /// Robot dustu mu: egim esigi asildi veya robot "fallen" bildirdi.
  static bool isFall(RobotTelemetry t, EvaluationThresholds th) =>
      (t.tiltDeg != null && t.tiltDeg!.abs() >= th.fallTiltDeg) ||
      t.state == RobotReportedState.fallen;

  static RobotTelemetry? firstFall(TestRecording rec, EvaluationThresholds th) {
    for (final t in rec.telemetry) {
      if (isFall(t, th)) return t;
    }
    return null;
  }

  static double? maxAbsTilt(Iterable<RobotTelemetry> samples) {
    final tilts = samples.where((t) => t.tiltDeg != null).map((t) => t.tiltDeg!.abs());
    if (tilts.isEmpty) return null;
    return tilts.reduce((a, b) => a > b ? a : b);
  }

  /// Test boyunca robot dusmedi mi (egim telemetrisi ile).
  static CriterionResult noFall(TestRecording rec, EvaluationThresholds th) {
    final maxTilt = maxAbsTilt(rec.telemetry);
    final hasState = rec.telemetry.any((t) => t.state != null);
    if (maxTilt == null && !hasState) {
      return CriterionResult(
        id: 'no_fall',
        label: 'Denge korundu',
        expected: '|eğim| < ${Fmt.degrees(th.fallTiltDeg)}',
        measured: Fmt.empty,
        status: CriterionStatus.missing,
        source: DataSource.telemetry,
      );
    }
    final fall = firstFall(rec, th);
    return CriterionResult(
      id: 'no_fall',
      label: 'Denge korundu',
      expected: '|eğim| < ${Fmt.degrees(th.fallTiltDeg)}',
      measured: fall == null
          ? 'En büyük eğim ${Fmt.degrees(maxTilt)}'
          : 'Düşme: ${Fmt.seconds(fall.receivedAt.difference(rec.startedAt).inMilliseconds / 1000)}',
      status: fall == null ? CriterionStatus.pass : CriterionStatus.fail,
      source: DataSource.telemetry,
    );
  }

  /// Sarj zamanlamasi: robot ne zaman yerlesti, sarj ne zaman basladi.
  static ChargeTiming chargeTiming(TestRecording rec) {
    final chargingAtStart = rec.telemetry.isNotEmpty && rec.telemetry.first.charging == true;

    // Yerlesme ani: once robotun "docked" bildirimi, yoksa kameranin "istasyonda" tespiti.
    DateTime? dockAt;
    DataSource? dockSource;
    for (final t in rec.telemetry) {
      if (t.docked == true || t.state == RobotReportedState.docked) {
        dockAt = t.receivedAt;
        dockSource = DataSource.telemetry;
        break;
      }
    }
    if (dockAt == null) {
      for (final m in rec.motion) {
        if (m.atStation == true) {
          dockAt = m.time;
          dockSource = DataSource.camera;
          break;
        }
      }
    }

    // Sarj baslangici: donanimsal CHG/STAT sinyalinin true oldugu ilk paket.
    DateTime? chargeAt;
    for (final t in rec.telemetry) {
      if (t.charging == true && (dockAt == null || !t.receivedAt.isBefore(dockAt))) {
        chargeAt = t.receivedAt;
        break;
      }
    }
    return ChargeTiming(
      dockAt: dockAt,
      dockSource: dockSource,
      chargeAt: chargeAt,
      chargingAtStart: chargingAtStart,
    );
  }

  /// Sartname 4.3 / 5.2: dogru yerlesmeden sonra sarj en gec 5 s icinde baslar.
  static CriterionResult chargeStart(TestRecording rec, EvaluationThresholds th) {
    final ct = chargeTiming(rec);
    final expected = 'Yerleşme → şarj ≤ ${Fmt.seconds(th.chargeStartWindowSeconds)}';
    if (ct.chargingAtStart) {
      return CriterionResult(
        id: 'charge_start',
        label: 'Şarj başlangıcı',
        expected: expected,
        measured: 'Test başında zaten şarjda',
        status: CriterionStatus.fail,
        source: DataSource.telemetry,
      );
    }
    if (ct.dockAt == null) {
      return CriterionResult(
        id: 'charge_start',
        label: 'Şarj başlangıcı',
        expected: expected,
        measured: 'Yerleşme anı tespit edilemedi',
        // Ne robot "docked" bildiriyor ne de kamera istasyonu goruyor.
        status: ct.chargeAt == null ? CriterionStatus.fail : CriterionStatus.missing,
        source: DataSource.telemetry,
      );
    }
    if (ct.chargeAt == null) {
      return CriterionResult(
        id: 'charge_start',
        label: 'Şarj başlangıcı',
        expected: expected,
        measured: 'Şarj başlamadı',
        status: CriterionStatus.fail,
        source: DataSource.telemetry,
      );
    }
    final delay = ct.delaySeconds!;
    return CriterionResult(
      id: 'charge_start',
      label: 'Şarj başlangıcı',
      expected: expected,
      measured: '${Fmt.seconds(delay)} (yerleşme: ${ct.dockSource!.label})',
      status: delay <= th.chargeStartWindowSeconds ? CriterionStatus.pass : CriterionStatus.fail,
      source: DataSource.telemetry,
    );
  }
}

class ChargeTiming {
  const ChargeTiming({this.dockAt, this.dockSource, this.chargeAt, this.chargingAtStart = false});

  final DateTime? dockAt;
  final DataSource? dockSource;
  final DateTime? chargeAt;
  final bool chargingAtStart;

  double? get delaySeconds => (dockAt == null || chargeAt == null)
      ? null
      : chargeAt!.difference(dockAt!).inMilliseconds / 1000;
}
