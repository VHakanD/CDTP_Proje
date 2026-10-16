import '../models/criterion.dart';
import '../models/motion.dart';
import '../models/scene_setup.dart';
import '../models/telemetry.dart';
import '../models/test_task.dart';

/// Bir test koşusunda biriken veri ve görev kuralları (wireframes/README → Kararlar).
///
/// Ölçülemeyen her ölçüt KALDI'dır; ayrı bir "geçersiz" sonucu yoktur.
class TaskRun {
  TaskRun({required this.task, required this.scene, this.expected});

  final TaskKind task;
  final SceneSetup scene;
  final Heading? expected;

  static const targetSeconds = 30;
  static const toleranceSeconds = 2;
  static const minDistanceM = 0.8;
  static const maxDistanceM = 1.2;
  static const chargeWithin = Duration(seconds: 5);
  static const waitAtTarget = Duration(seconds: 5);
  static const settleForAutoEnd = Duration(seconds: 2);
  static const maxGap = Duration(seconds: 2);

  Duration elapsed = Duration.zero;
  final events = <(Duration, String)>[];

  // hareket
  bool _sawVisible = false;
  bool _sawMoving = false;
  final _headingTime = <Heading, int>{};
  Duration? _lastSnapAt;
  MotionSnapshot _lastSnap = MotionSnapshot.initial;
  Duration? _staticSince;
  Duration? _inZoneStaticSince;
  Duration _longestZoneWait = Duration.zero;

  // telemetri
  bool _sawTelemetry = false;
  bool _fell = false;
  bool _boxSeen = false;
  bool _boxDropped = false;
  Duration? _dockAt;
  Duration? _chargeAt;
  Duration? _zoneReachedAt;

  void onSnapshot(Duration t, MotionSnapshot m) {
    elapsed = t > elapsed ? t : elapsed;
    final dt = _lastSnapAt == null ? Duration.zero : t - _lastSnapAt!;
    _lastSnapAt = t;
    if (m.quality != TrackQuality.lost) _sawVisible = true;
    if (m.state == MotionState.moving) {
      if (!_sawMoving) _log(t, 'hareket başladı · ${m.heading.label}');
      _sawMoving = true;
      _headingTime.update(m.heading, (v) => v + dt.inMilliseconds,
          ifAbsent: () => dt.inMilliseconds);
    }
    if (m.state != _lastSnap.state) _log(t, m.state.label);
    if (m.quality == TrackQuality.lost && _lastSnap.quality != TrackQuality.lost) {
      _log(t, 'robot kayboldu');
    }

    final isStatic = m.state == MotionState.staticBalance && m.quality != TrackQuality.lost;
    _staticSince = isStatic ? (_staticSince ?? t) : null;

    final inZone = _inTargetZone(m);
    if (inZone && _zoneReachedAt == null) {
      _zoneReachedAt = t;
      _log(t, 'hedef bölgeye ulaştı');
    }
    if (inZone && isStatic) {
      _inZoneStaticSince ??= t;
      final waited = t - _inZoneStaticSince!;
      if (waited > _longestZoneWait) _longestZoneWait = waited;
      if (_dockAt == null && task == TaskKind.charging && waited >= const Duration(seconds: 1)) {
        _dockAt = _inZoneStaticSince;
        _log(t, 'yerleşme (kamera)');
      }
    } else {
      _inZoneStaticSince = null;
    }
    _lastSnap = m;
  }

  void onTelemetry(Duration t, Telemetry x) {
    elapsed = t > elapsed ? t : elapsed;
    _sawTelemetry = true;
    if (x.fallen && !_fell) {
      _fell = true;
      _log(t, 'robot düştü');
    }
    if (x.boxPresent != null) {
      _boxSeen = true;
      if (x.boxPresent == false && !_boxDropped) {
        _boxDropped = true;
        _log(t, 'kutu düştü');
      }
    }
    if (x.docked == true && _dockAt == null) {
      _dockAt = t;
      _log(t, 'yerleşme (robot)');
    }
    if (x.charging && _chargeAt == null) {
      _chargeAt = t;
      _log(t, 'şarj başladı');
    }
  }

  void _log(Duration t, String text) => events.add((t, text));

  bool _inTargetZone(MotionSnapshot m) {
    final z = scene.targetZone;
    final c = m.center;
    return z != null && c != null && m.quality != TrackQuality.lost && z.contains(c);
  }

  Heading? get dominantHeading {
    if (_headingTime.isEmpty) return null;
    return (_headingTime.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  /// Önceden tanımlı bitiş koşulu sağlandı mı (wireframe 05 → otomatik bitiş).
  bool get autoEnd => switch (task) {
        TaskKind.staticBalance => elapsed >= const Duration(seconds: targetSeconds) || _fell,
        TaskKind.guidance => (_lastSnap.distanceM ?? 0) >= 0.3 &&
            _staticSince != null &&
            elapsed - _staticSince! >= settleForAutoEnd,
        TaskKind.charging =>
          _chargeAt != null || (_dockAt != null && elapsed - _dockAt! > chargeWithin),
        TaskKind.integrated => _chargeAt != null && _zoneReachedAt != null,
      };

  List<Criterion> evaluate({required Duration gapMax}) {
    final list = switch (task) {
      TaskKind.staticBalance => _evalA(),
      TaskKind.guidance => _evalB(),
      TaskKind.charging => _evalC(),
      TaskKind.integrated => _evalE(),
    };
    list.add(Criterion(
      name: 'Bağlantı',
      measured: _sawTelemetry ? 'en uzun boşluk ${_s(gapMax)}' : 'veri yok',
      target: '≤ 2 s kopma',
      result: _sawTelemetry && gapMax <= maxGap ? CriterionResult.pass : CriterionResult.fail,
      reason: _sawTelemetry ? null : 'ölçülemedi',
    ));
    return list;
  }

  static Verdict verdictOf(List<Criterion> c) =>
      c.any((x) => x.result == CriterionResult.fail) ? Verdict.fail : Verdict.pass;

  List<Criterion> _evalA() {
    final secs = elapsed.inMilliseconds / 1000;
    final timeOk = (secs - targetSeconds).abs() <= toleranceSeconds;
    return [
      Criterion(
        name: 'Süre',
        measured: '${_n(secs)} s',
        target: '$targetSeconds s ±$toleranceSeconds',
        result: timeOk ? CriterionResult.pass : CriterionResult.fail,
      ),
      _visibleOr(Criterion(
        name: 'Hareket',
        measured: _sawMoving ? 'hareket etti' : 'statik denge',
        target: 'statik denge',
        result: _sawMoving ? CriterionResult.fail : CriterionResult.pass,
      )),
      Criterion(
        name: 'Denge',
        measured: !_sawTelemetry ? 'veri yok' : (_fell ? 'düştü' : 'korundu'),
        target: 'düşmeden',
        result: _sawTelemetry && !_fell ? CriterionResult.pass : CriterionResult.fail,
        reason: _sawTelemetry ? null : 'ölçülemedi',
      ),
    ];
  }

  List<Criterion> _evalB() {
    final d = _lastSnap.distanceM;
    final h = dominantHeading;
    return [
      Criterion(
        name: 'Yön',
        measured: h?.label ?? '—',
        target: expected?.label ?? 'seçilmedi',
        result: h != null && h == expected ? CriterionResult.pass : CriterionResult.fail,
        reason: expected == null ? 'beklenen yön seçilmedi' : (h == null ? 'ölçülemedi' : null),
      ),
      Criterion(
        name: 'Mesafe',
        measured: d == null ? '—' : '${_n(d)} m',
        target: '${_n(minDistanceM)}–${_n(maxDistanceM)} m',
        result: d != null && d >= minDistanceM && d <= maxDistanceM
            ? CriterionResult.pass
            : CriterionResult.fail,
        reason: d == null ? 'ölçülemedi (ölçek yok)' : null,
      ),
      _visibleOr(Criterion(
        name: 'Son konum',
        measured: _staticSince != null ? 'durdu' : 'hareketli',
        target: 'robot durur',
        result: _staticSince != null ? CriterionResult.pass : CriterionResult.fail,
      )),
      Criterion(name: 'Süre', measured: '${_n(elapsed.inMilliseconds / 1000)} s', target: 'bilgi', result: CriterionResult.info),
    ];
  }

  List<Criterion> _evalC() {
    final dock = _dockAt;
    final charge = _chargeAt;
    final delay = (dock != null && charge != null) ? charge - dock : null;
    return [
      Criterion(
        name: 'Yerleşme',
        measured: dock == null ? 'tespit edilmedi' : 'tespit edildi',
        target: 'dock\'a otur',
        result: dock != null ? CriterionResult.pass : CriterionResult.fail,
        reason: dock == null ? 'ölçülemedi' : null,
      ),
      Criterion(
        name: 'Şarj başlangıcı',
        measured: delay == null ? '—' : _s(delay < Duration.zero ? Duration.zero : delay),
        target: '≤ 5 s',
        result: delay != null && delay <= chargeWithin ? CriterionResult.pass : CriterionResult.fail,
        reason: charge == null ? 'şarj başlamadı' : null,
      ),
    ];
  }

  List<Criterion> _evalE() {
    final charged = _chargeAt != null;
    return [
      Criterion(
        name: 'Yük durumu',
        measured: !_boxSeen ? 'veri yok' : (_boxDropped ? 'düştü' : 'robot üzerinde'),
        target: 'kutu düşmez',
        result: _boxSeen && !_boxDropped ? CriterionResult.pass : CriterionResult.fail,
        reason: _boxSeen ? null : 'ölçülemedi',
      ),
      Criterion(
        name: 'Hedefte bekleme',
        measured: _s(_longestZoneWait),
        target: '≥ 5 s',
        result: _longestZoneWait >= waitAtTarget ? CriterionResult.pass : CriterionResult.fail,
        reason: scene.targetZone == null ? 'hedef bölge çizilmedi' : null,
      ),
      Criterion(
        name: 'Şarj',
        measured: charged ? 'başladı' : 'başlamadı',
        target: 'otomatik başlar',
        result: charged ? CriterionResult.pass : CriterionResult.fail,
      ),
      Criterion(
        name: 'Mesafe',
        measured: _lastSnap.distanceM == null ? '—' : '${_n(_lastSnap.distanceM!)} m',
        target: 'bilgi',
        result: CriterionResult.info,
      ),
    ];
  }

  Criterion _visibleOr(Criterion c) => _sawVisible
      ? c
      : Criterion(name: c.name, measured: '—', target: c.target, result: CriterionResult.fail, reason: 'ölçülemedi (robot görülmedi)');

  static String _n(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
  static String _s(Duration d) => '${(d.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',')} s';
}
