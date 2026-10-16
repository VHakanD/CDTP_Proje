import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/robot_repository.dart';
import '../../../../data/repositories/tracking_repository.dart';
import '../../../../data/services/tracker/sim_tracker.dart';
import '../../../../domain/models/motion.dart';
import '../../../core/session_store.dart';

enum TapMode { none, p1, p2, zoneA, zoneB }

/// 04 · Sahne hazırlama: telefon sabit, ölçek (P1–P2), robot kadrajda, hedef bölge.
class SceneViewModel extends ChangeNotifier {
  SceneViewModel(this._session, this.tracking, this._robot);

  final SessionStore _session;
  final TrackingRepository tracking;
  final RobotRepository _robot;
  StreamSubscription<TrackSample>? _sub;

  TapMode mode = TapMode.none;
  Offset? _zoneA;
  TrackSample? lastSample;

  SessionStore get session => _session;

  Future<void> init() async {
    await tracking.open();
    _session.updateScene(_session.scene.copyWith(sensorAspect: tracking.tracker!.sensorAspect));
    _sub = tracking.tracker!.samples.listen((s) {
      lastSample = s;
      notifyListeners();
    });
    notifyListeners();
  }

  bool get robotVisible {
    final s = lastSample;
    return s != null && s.center != null && s.confidence >= 0.6 && _robot.now() - s.t < const Duration(seconds: 1);
  }

  List<String> get missing => _session.missingSteps(robotVisible: robotVisible);
  bool get ready => missing.isEmpty;

  void setPhoneFixed(bool v) => _session.updateScene(_session.scene.copyWith(phoneFixed: v));

  void setMarkerLength(double m) {
    if (m > 0) _session.updateScene(_session.scene.copyWith(markerLengthM: m));
  }

  void startMode(TapMode m) {
    mode = m;
    notifyListeners();
  }

  /// Kamera alanına dokunuş (sensör koordinatı).
  void onTap(Offset p) {
    final s = _session.scene;
    switch (mode) {
      case TapMode.p1:
        _session.updateScene(s.copyWith(p1: p));
        mode = TapMode.p2;
      case TapMode.p2:
        _session.updateScene(s.copyWith(p2: p));
        mode = TapMode.none;
      case TapMode.zoneA:
        _zoneA = p;
        mode = TapMode.zoneB;
      case TapMode.zoneB:
        _session.updateScene(s.copyWith(targetZone: Rect.fromPoints(_zoneA!, p)));
        mode = TapMode.none;
      case TapMode.none:
        return;
    }
    notifyListeners();
  }

  /// Simülatör sahnesindeki bilinen işaret ve istasyonu kullanır.
  void useSimScene() {
    _session.updateScene(_session.scene.copyWith(
      p1: SimTracker.markerP1,
      p2: SimTracker.markerP2,
      markerLengthM: 1,
      targetZone: SimTracker.targetZone,
      phoneFixed: true,
    ));
    notifyListeners();
  }

  /// Başlangıç konumu: o anki robot konumu.
  void captureStart() {
    final c = lastSample?.center;
    if (c != null) _session.updateScene(_session.scene.copyWith(start: c));
  }

  void reset() {
    _session.resetScene();
    mode = TapMode.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
