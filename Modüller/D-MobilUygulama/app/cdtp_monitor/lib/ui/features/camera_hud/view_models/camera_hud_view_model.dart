import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/report_repository.dart';
import '../../../../data/repositories/robot_repository.dart';
import '../../../../data/repositories/tracking_repository.dart';
import '../../../../data/services/tracker/motion_tracker.dart';
import '../../../../domain/models/link_health.dart';
import '../../../../domain/models/motion.dart';
import '../../../../domain/models/telemetry.dart';
import '../../../../domain/models/test_report.dart';
import '../../../../domain/use_cases/motion_analyzer.dart';
import '../../../../domain/use_cases/task_evaluator.dart';
import '../../../core/session_store.dart';

enum HudPhase { ready, recording, sealing, ended }

/// 05 · Kamera + HUD. Takip örneklerini ve telemetriyi birleştirir, testi
/// başlatır/bitirir, otomatik bitişi algılar ve raporu mühürler.
class CameraHudViewModel extends ChangeNotifier {
  CameraHudViewModel({
    required this.session,
    required this.robot,
    required this.reports,
    required this.tracking,
  });

  static const tickEvery = Duration(milliseconds: 100);
  static const silentAfter = Duration(milliseconds: 300);

  final SessionStore session;
  final RobotRepository robot;
  final ReportRepository reports;
  final TrackingRepository tracking;

  late MotionAnalyzer _analyzer;
  TaskRun? _run;
  StreamSubscription<TrackSample>? _trackSub;
  StreamSubscription<(Duration, Telemetry)>? _telSub;
  Timer? _ticker;
  Duration? _startT;
  DateTime? _startWall;
  Duration _lastSampleT = Duration.zero;
  int _telemetryCount = 0;

  HudPhase phase = HudPhase.ready;
  MotionSnapshot motion = MotionSnapshot.initial;
  Duration elapsed = Duration.zero;
  bool autoEnded = false;
  TestReport? report;
  String? error;

  FrameRatio get ratio => session.ratio;
  LinkState get link => robot.link.value;
  Telemetry? get telemetry => robot.latest.value;
  bool get recording => phase == HudPhase.recording;
  bool get canStart => phase == HudPhase.ready && link.usable && motion.quality != TrackQuality.lost;

  MotionTracker? _subscribed;
  bool _disposed = false;

  /// Kamera açılamadıysa nedeni (ekranda "Tekrar dene" ile gösterilir).
  String? get trackingError => tracking.error;

  Future<void> init() async {
    _analyzer = MotionAnalyzer(session.scene);
    _telSub = robot.telemetry.listen(_onTelemetry);
    robot.link.addListener(notifyListeners);
    tracking.addListener(_follow);
    _ticker = Timer.periodic(tickEvery, (_) => _tick());
    await tracking.open();
    _follow();
  }

  /// Takip kaynağı değişince (Tekrar dene, arka plandan dönüş) yenisine abone olur.
  void _follow() {
    if (_disposed) return;
    final t = tracking.tracker;
    if (identical(t, _subscribed)) {
      notifyListeners();
      return;
    }
    _trackSub?.cancel();
    _trackSub = null;
    _subscribed = t;
    if (t != null) _trackSub = t.samples.listen(_onSample);
    notifyListeners();
  }

  Future<void> retry() => tracking.retry();

  /// Uygulama arka plana geçti: kayıt yoksa kamerayı bırak.
  Future<void> pause() async {
    if (phase == HudPhase.recording || phase == HudPhase.sealing) return;
    await tracking.close();
  }

  /// Uygulama öne geldi: kamerayı yeniden aç (açıksa bir şey yapmaz).
  Future<void> resume() => tracking.open();

  void setRatio(FrameRatio r) {
    session.setRatio(r);
    notifyListeners();
  }

  void _onSample(TrackSample s) {
    _lastSampleT = s.t;
    motion = _analyzer.add(s, telemetry: telemetry);
    if (recording) _run!.onSnapshot(s.t - _startT!, motion);
    notifyListeners();
  }

  void _onTelemetry((Duration, Telemetry) e) {
    if (!recording) return;
    _telemetryCount++;
    _run!.onTelemetry(e.$1 - _startT!, e.$2);
  }

  void _tick() {
    final now = robot.now();
    if (now - _lastSampleT > silentAfter) {
      motion = _analyzer.tick(now, telemetry: telemetry);
      if (recording) _run!.onSnapshot(now - _startT!, motion);
    }
    if (recording) {
      elapsed = now - _startT!;
      if (_run!.autoEnd) {
        autoEnded = true;
        unawaited(stop());
      }
    }
    notifyListeners();
  }

  Future<void> start() async {
    if (!canStart) return;
    _analyzer = MotionAnalyzer(session.scene); // mesafe ve iz sıfırdan
    _run = TaskRun(task: session.task!, scene: session.scene, expected: session.expected);
    _startT = robot.now();
    _startWall = DateTime.now();
    _telemetryCount = 0;
    elapsed = Duration.zero;
    autoEnded = false;
    robot.resetGap();
    await tracking.startRecording();
    robot.sendTestEvent('start', session.task!, _startWall!.toIso8601String());
    _run!.events.add((Duration.zero, 'Test başladı'));
    phase = HudPhase.recording;
    notifyListeners();
  }

  /// Elle ya da otomatik bitiş: değerlendir, mühürle.
  Future<void> stop() async {
    if (!recording) return;
    phase = HudPhase.sealing;
    notifyListeners();
    final run = _run!;
    run.events.add((elapsed, autoEnded ? 'Bitiş: otomatik (${run.task.endRule})' : 'Bitiş: elle'));
    final criteria = run.evaluate(gapMax: link.maxGap);
    final video = await tracking.stopRecording();
    robot.sendTestEvent('stop', run.task, _startWall!.toIso8601String());
    try {
      report = await reports.seal(ReportDraft(
        task: run.task,
        startedAt: _startWall!,
        endedAt: _startWall!.add(elapsed),
        criteria: criteria,
        events: [for (final e in run.events) (e.$1.inMilliseconds, e.$2)],
        conditions: {
          'scene': session.scene.toJson(),
          'ratio': ratio.label,
          'tracker': tracking.tracker?.name,
          'max_gap_ms': link.maxGap.inMilliseconds,
        },
        telemetryCount: _telemetryCount,
        expected: session.expected?.label,
        videoPath: video,
      ));
      session.lastReportId = report!.id;
    } catch (e) {
      error = 'Rapor kaydedilemedi: $e';
    }
    phase = HudPhase.ended;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _trackSub?.cancel();
    _telSub?.cancel();
    robot.link.removeListener(notifyListeners);
    tracking.removeListener(_follow);
    super.dispose();
  }
}
