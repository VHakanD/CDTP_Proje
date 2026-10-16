import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/link_health.dart';
import '../../domain/models/telemetry.dart';
import '../../domain/models/test_task.dart';
import '../services/protocol_codec.dart';
import '../services/robot_socket_service.dart';

/// Robot bağlantısının tek doğruluk kaynağı: telemetri, bağlantı sağlığı,
/// simülatör konumu. Uygulama robota hareket komutu göndermez.
class RobotRepository {
  RobotRepository(this._socket, {Duration Function()? clock})
      : _clock = clock ?? _stopwatchClock();

  static const appVersion = '0.1.0';
  static const healthEvery = Duration(milliseconds: 250);
  static const pingEvery = Duration(seconds: 1);
  static const reconnectEvery = Duration(milliseconds: 500);
  static const historyKeep = Duration(seconds: 90);

  final RobotSocketService _socket;
  final Duration Function() _clock;

  final link = ValueNotifier<LinkState>(LinkState.initial);
  final latest = ValueNotifier<Telemetry?>(null);
  final _telemetry = StreamController<(Duration, Telemetry)>.broadcast();
  final _pose = StreamController<(Duration, SimPose)>.broadcast();
  final _history = <(Duration, Telemetry)>[];
  final _arrivals = <Duration>[];

  StreamSubscription<String>? _sub;
  Timer? _health;
  Timer? _ping;
  Timer? _retry;
  Duration? _lastTelemetryAt;
  Duration _maxGap = Duration.zero;
  int _pingId = 0;
  int badMessages = 0;
  bool _wantConnected = false;

  /// (test başından bağımsız monoton zaman, telemetri)
  Stream<(Duration, Telemetry)> get telemetry => _telemetry.stream;
  Stream<(Duration, SimPose)> get simPose => _pose.stream;
  Duration now() => _clock();

  /// Bağlantı adresi simülatörü gösteriyorsa kamera ekranı sanal sahneyi kullanır.
  bool get isSimulator {
    final h = link.value.uri?.host ?? '';
    return h == 'localhost' || h == '127.0.0.1' || link.value.device?.contains('SIM') == true;
  }

  List<Telemetry> history(Duration window) {
    final from = now() - window;
    return [for (final e in _history) if (e.$1 >= from) e.$2];
  }

  Future<void> connect(Uri uri) async {
    _wantConnected = true;
    link.value = LinkState(level: LinkLevel.connecting, uri: uri);
    await _open(uri);
  }

  Future<void> _open(Uri uri) async {
    try {
      final stream = await _socket.connect(uri);
      _sub = stream.listen(_onText, onDone: _onClosed, onError: (_) => _onClosed());
      _socket.send(ProtocolCodec.encodeHello(appVersion));
      link.value = link.value.copyWith(level: LinkLevel.slow, clearError: true);
      _lastTelemetryAt ??= now();
      _health ??= Timer.periodic(healthEvery, (_) => _checkHealth());
      _ping ??= Timer.periodic(pingEvery, (_) => _socket.send(ProtocolCodec.encodePing(++_pingId)));
    } catch (e) {
      link.value = link.value.copyWith(
        level: LinkLevel.disconnected,
        error: 'Robot ${RobotSocketService.connectTimeout.inSeconds} s içinde yanıt vermedi. '
            'Telefonun robotla aynı Wi-Fi ağında olduğunu kontrol edin.',
      );
      if (_wantConnected && link.value.telemetryReceived) _scheduleRetry(uri);
    }
  }

  void _onClosed() {
    _sub = null;
    if (_wantConnected) {
      link.value = link.value.copyWith(level: LinkLevel.lost);
      _scheduleRetry(link.value.uri!);
    }
  }

  void _scheduleRetry(Uri uri) {
    _retry?.cancel();
    _retry = Timer(reconnectEvery, () {
      if (_wantConnected && !_socket.isOpen) _open(uri);
    });
  }

  void _onText(String raw) {
    final msg = ProtocolCodec.decode(raw);
    final t = now();
    switch (msg) {
      case null:
        badMessages++;
      case Hello(:final device):
        link.value = link.value.copyWith(device: device, helloReceived: true);
      case Telemetry():
        _onTelemetry(t, msg);
      case SimPose():
        _pose.add((t, msg));
      case Pong() || RobotEvent() || UnknownMessage():
        break; // bağlantı sağlığını etkilemez
    }
  }

  void _onTelemetry(Duration t, Telemetry x) {
    final prev = _lastTelemetryAt;
    if (prev != null && t - prev > _maxGap) _maxGap = t - prev;
    _lastTelemetryAt = t;
    _arrivals.add(t);
    _arrivals.removeWhere((a) => t - a > const Duration(seconds: 10));
    _history.add((t, x));
    _history.removeWhere((e) => t - e.$1 > historyKeep);
    latest.value = x;
    _telemetry.add((t, x));
    link.value = link.value.copyWith(telemetryReceived: true);
    _checkHealth();
  }

  void _checkHealth() {
    final t = now();
    final since = _lastTelemetryAt == null ? Duration.zero : t - _lastTelemetryAt!;
    final level = LinkHealth.levelFor(since, socketOpen: _socket.isOpen);
    final span = _arrivals.isEmpty ? 0 : (t - _arrivals.first).inMilliseconds / 1000;
    final hz = span <= 0 ? 0.0 : (_arrivals.length - 1).clamp(0, 1 << 30) / span;
    final gap = since > _maxGap ? since : _maxGap;
    link.value = link.value.copyWith(
      level: link.value.telemetryReceived || level == LinkLevel.disconnected
          ? level
          : LinkLevel.connecting,
      sinceLastTelemetry: since,
      hz: hz,
      maxGap: gap,
    );
  }

  /// Test başında çağrılır: en uzun boşluk ölçümü sıfırlanır.
  void resetGap() {
    _maxGap = Duration.zero;
    link.value = link.value.copyWith(maxGap: Duration.zero);
  }

  void sendTestEvent(String action, TaskKind task, String testId) =>
      _socket.send(ProtocolCodec.encodeTestEvent(action, task, testId));

  Future<void> disconnect() async {
    _wantConnected = false;
    _retry?.cancel();
    _health?.cancel();
    _ping?.cancel();
    _health = _ping = null;
    await _sub?.cancel();
    await _socket.close();
    _lastTelemetryAt = null;
    _arrivals.clear();
    latest.value = null;
    link.value = LinkState.initial;
  }

  static Duration Function() _stopwatchClock() {
    final sw = Stopwatch()..start();
    return () => sw.elapsed;
  }
}
