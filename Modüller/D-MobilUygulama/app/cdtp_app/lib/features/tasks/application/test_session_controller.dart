import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../camera/application/camera_session_controller.dart';
import '../../camera/data/video_storage.dart';
import '../../camera/domain/motion_sample.dart';
import '../../connection/application/robot_connection_controller.dart';
import '../../reports/application/report_providers.dart';
import '../../reports/domain/test_report.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/evaluators/task_evaluators.dart';
import '../domain/test_recording.dart';
import '../domain/test_task.dart';
import 'report_payload_builder.dart';

enum SessionPhase {
  setup('Hazır'),
  running('Sürüyor'),
  saving('Kaydediliyor'),
  finished('Tamamlandı');

  const SessionPhase(this.label);
  final String label;
}

@immutable
class TestSessionState {
  const TestSessionState({
    this.phase = SessionPhase.setup,
    this.task,
    this.params = const TaskParams(),
    this.testId,
    this.startedAt,
    this.elapsed = Duration.zero,
    this.telemetryCount = 0,
    this.lastMotion,
    this.videoRecording = false,
    this.endReason,
    this.report,
    this.error,
  });

  final SessionPhase phase;
  final TestTask? task;
  final TaskParams params;
  final String? testId;
  final DateTime? startedAt;
  final Duration elapsed;
  final int telemetryCount;
  final MotionSample? lastMotion;
  final bool videoRecording;
  final EndReason? endReason;

  /// Test bitip kaydedildiginde olusan rapor.
  final TestReport? report;
  final String? error;

  TestSessionState copyWith({
    SessionPhase? phase,
    String? testId,
    DateTime? startedAt,
    Duration? elapsed,
    int? telemetryCount,
    MotionSample? lastMotion,
    bool? videoRecording,
    EndReason? endReason,
    TestReport? report,
    String? error,
  }) =>
      TestSessionState(
        phase: phase ?? this.phase,
        task: task,
        params: params,
        testId: testId ?? this.testId,
        startedAt: startedAt ?? this.startedAt,
        elapsed: elapsed ?? this.elapsed,
        telemetryCount: telemetryCount ?? this.telemetryCount,
        lastMotion: lastMotion ?? this.lastMotion,
        videoRecording: videoRecording ?? this.videoRecording,
        endReason: endReason ?? this.endReason,
        report: report ?? this.report,
        error: error ?? this.error,
      );
}

/// Bir olcum testinin yasam dongusunu yonetir.
///
///  select()  -> gorev ve parametre secilir
///  start()   -> "Testi Baslat": zaman damgasi alinir, video kaydi ve veri toplama baslar
///  (tick)    -> her 200 ms'de sure guncellenir, otomatik bitis kosulu kontrol edilir
///  stop()    -> "Testi Bitir" veya otomatik bitis: degerlendirme + degistirilemez rapor
class TestSessionController extends Notifier<TestSessionState> {
  static const _tickPeriod = Duration(milliseconds: 200);

  TestRecording? _rec;
  TaskEvaluator? _evaluator;
  EvaluationThresholds? _thresholds;
  StreamSubscription<dynamic>? _telemetrySub;
  StreamSubscription<dynamic>? _eventSub;
  StreamSubscription<dynamic>? _motionSub;
  Timer? _ticker;

  @override
  TestSessionState build() {
    ref.onDispose(_cancelAll);
    return const TestSessionState();
  }

  /// Test ekranina girerken gorev secilir.
  void select(TestTask task, TaskParams params) {
    if (state.phase == SessionPhase.running || state.phase == SessionPhase.saving) return;
    state = TestSessionState(task: task, params: params);
  }

  /// Ayni gorevi tekrar yapmak icin (orn. Ö5'in 4 tekrari).
  void reset() {
    if (state.phase == SessionPhase.running || state.phase == SessionPhase.saving) return;
    state = TestSessionState(task: state.task, params: state.params);
  }

  Future<void> start() async {
    final task = state.task;
    if (task == null || state.phase != SessionPhase.setup) return;

    // Sartname: "Testi Baslat"a basildigi an test suresinin baslangic zaman damgasidir.
    final startedAt = DateTime.now();
    final testId = _newTestId(startedAt);

    final settings = ref.read(settingsProvider);
    final conn = ref.read(robotConnectionProvider.notifier);
    final tracker = ref.read(motionTrackerProvider);

    _thresholds = settings.thresholds;
    _evaluator = TaskEvaluator.forTask(task);
    final rec = _rec = TestRecording(
      testId: testId,
      task: task,
      params: state.params,
      startedAt: startedAt,
      trackerImplemented: tracker.isImplemented,
      robotInfo: ref.read(robotConnectionProvider).info,
    );

    // Veri toplama: robot telemetrisi, robot olaylari, kamera ornekleri.
    _telemetrySub = conn.telemetryStream.listen(rec.telemetry.add);
    _eventSub = conn.eventStream.listen(
      (e) => rec.events.add(RecordedEvent(time: e.receivedAt, name: e.name, value: e.value)),
    );
    await tracker.start();
    _motionSub = tracker.samples.listen((m) {
      rec.motion.add(m);
      state = state.copyWith(lastMotion: m);
    });

    // Video kaydi (kamera hazirsa). Tespit yontemi kare istiyorsa kareler ona da gider.
    var recording = false;
    if (settings.recordVideo) {
      recording = await ref.read(cameraSessionProvider.notifier).startRecording(
            onFrame: tracker.needsFrames ? tracker.processFrame : null,
          );
    }

    conn.sendTestMarker(action: 'start', task: task.name, testId: testId);
    state = state.copyWith(
      phase: SessionPhase.running,
      testId: testId,
      startedAt: startedAt,
      elapsed: Duration.zero,
      videoRecording: recording,
    );
    _ticker = Timer.periodic(_tickPeriod, (_) => _tick());
  }

  void _tick() {
    final rec = _rec;
    if (rec == null || state.phase != SessionPhase.running) return;
    final now = DateTime.now();
    state = state.copyWith(elapsed: rec.elapsedAt(now), telemetryCount: rec.telemetry.length);
    final reason = _evaluator!.checkAutoStop(rec, _thresholds!, now);
    if (reason != null) stop(reason);
  }

  /// Testi bitirir, degerlendirir ve raporu kaydeder.
  Future<void> stop([EndReason reason = EndReason.manual]) async {
    final rec = _rec;
    if (rec == null || state.phase != SessionPhase.running) return;

    // Bitis zamani hemen alinir (video kapatma suresi olcume katilmasin).
    rec.endedAt = DateTime.now();
    state = state.copyWith(phase: SessionPhase.saving, elapsed: rec.elapsedAt(rec.endedAt!));
    _ticker?.cancel();
    await _telemetrySub?.cancel();
    await _eventSub?.cancel();
    await _motionSub?.cancel();

    final tracker = ref.read(motionTrackerProvider);
    await tracker.stop();
    ref.read(robotConnectionProvider.notifier)
        .sendTestMarker(action: 'stop', task: rec.task.name, testId: rec.testId);

    try {
      RecordedVideo? video;
      if (state.videoRecording) {
        video = await ref.read(cameraSessionProvider.notifier).stopRecording(rec.testId);
      }

      final evaluation = _evaluator!.evaluate(rec, _thresholds!);
      final payload = const ReportPayloadBuilder().build(
        rec: rec,
        evaluation: evaluation,
        thresholds: _thresholds!,
        endReason: reason,
        trackerName: tracker.name,
        video: video,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      );

      final report = await ref.read(reportRepositoryProvider).append(
            NewReport(
              testId: rec.testId,
              task: rec.task,
              verdict: evaluation.verdict,
              startedAt: rec.startedAt,
              durationMs: rec.endedAt!.difference(rec.startedAt).inMilliseconds,
              payload: payload,
            ),
          );
      ref
        ..invalidate(reportListProvider)
        ..invalidate(chainVerificationProvider);

      state = state.copyWith(
        phase: SessionPhase.finished,
        endReason: reason,
        report: report,
        videoRecording: false,
      );
    } catch (e) {
      state = state.copyWith(
        phase: SessionPhase.finished,
        endReason: reason,
        videoRecording: false,
        error: 'Rapor kaydedilemedi: $e',
      );
    } finally {
      _rec = null;
    }
  }

  /// Ornek: T20261013-142340-3FA2
  static String _newTestId(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final rnd = Random().nextInt(0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
    return 'T${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}-$rnd';
  }

  void _cancelAll() {
    _ticker?.cancel();
    _telemetrySub?.cancel();
    _eventSub?.cancel();
    _motionSub?.cancel();
  }
}

final testSessionProvider =
    NotifierProvider<TestSessionController, TestSessionState>(TestSessionController.new);
