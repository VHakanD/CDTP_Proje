import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'autopilot.dart';
import 'control_page.dart';
import 'robot_model.dart';

/// Robot ESP32-S3'ün ağ tarafını taklit eder.
///
/// - `ws://host:port/ws`    → uygulama: `hello`, 1 Hz `telemetry`, 10 Hz `sim_pose`, `pong`
/// - `ws://host:port/glove` → eldiven: `{"type":"glove_cmd","cmd":"forward","seq":1}`
///   (gerçek donanımda ESP-NOW ile gelir)
/// - `http://host:port/`    → kontrol sayfası (eldiven düğmeleri + senaryolar)
class SimServer {
  SimServer({this.port = 8765, this.telemetryHz = 1.0, RobotModel? robot}) : robot = robot ?? RobotModel() {
    pilot = Autopilot(this.robot);
  }

  final int port;
  final double telemetryHz;
  final RobotModel robot;
  late final Autopilot pilot;

  /// Kötü Wi-Fi taklidi: paketlerde 0–600 ms gecikme, %5 (konumda %10) kayıp.
  bool flakyWifi = false;
  final _rnd = math.Random();

  HttpServer? _http;
  final _apps = <WebSocket>{};
  final _gloves = <WebSocket>{};
  final _timers = <Timer>[];
  DateTime? _blackoutUntil;
  final _log = <String>[];

  int get boundPort => _http?.port ?? port;
  int get appClients => _apps.length;

  Future<void> start() async {
    _http = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _http!.listen(_handle, onError: (Object e) => stderr.writeln('http: $e'));
    var last = DateTime.now();
    _timers
      ..add(Timer.periodic(const Duration(milliseconds: 20), (_) {
        final now = DateTime.now();
        final dt = math.min(now.difference(last).inMicroseconds / 1e6, 0.1);
        last = now;
        robot.step(dt);
        final before = pilot.stepLabel;
        pilot.tick(dt);
        if (pilot.stepLabel != before && pilot.stepLabel != null) _say('Pilot: ${pilot.stepLabel}');
      }))
      ..add(Timer.periodic(Duration(microseconds: (1e6 / telemetryHz).round()), (_) {
        if (!_blackout) _send(robot.telemetry(), drop: 0.05);
      }))
      ..add(Timer.periodic(const Duration(milliseconds: 100), (_) => _send(robot.pose(), drop: 0.10)));
    _say('Robot simülatörü: http://localhost:$boundPort  ·  uygulama ws://<ip>:$boundPort/ws');
  }

  bool get _blackout => _blackoutUntil != null && DateTime.now().isBefore(_blackoutUntil!);

  Future<void> stop() async {
    for (final t in _timers) {
      t.cancel();
    }
    for (final s in [..._apps, ..._gloves]) {
      await s.close();
    }
    await _http?.close(force: true);
  }

  void _say(String m) {
    final line = '${DateTime.now().toIso8601String().substring(11, 19)} $m';
    _log.add(line);
    if (_log.length > 40) _log.removeAt(0);
    stdout.writeln(line);
  }

  /// Kötü Wi-Fi açıksa gecikmeli ya da hiç gönderir.
  void _send(Map<String, Object?> msg, {required double drop}) {
    if (!flakyWifi) return _broadcast(msg);
    if (_rnd.nextDouble() < drop) return;
    Timer(Duration(milliseconds: _rnd.nextInt(600)), () => _broadcast(msg));
  }

  void _broadcast(Map<String, Object?> msg) {
    final text = jsonEncode(msg);
    for (final s in _apps.toList()) {
      s.add(text);
    }
  }

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path;
    if (WebSocketTransformer.isUpgradeRequest(req) && (path == '/ws' || path == '/glove')) {
      final ws = await WebSocketTransformer.upgrade(req);
      path == '/ws' ? _onApp(ws) : _onGlove(ws);
      return;
    }
    switch (path) {
      case '/':
        req.response.headers.contentType = ContentType.html;
        req.response.write(controlPageHtml);
      case '/api/state':
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({
          ...robot.telemetry()..remove('seq'),
          ...robot.pose(),
          'app_clients': _apps.length,
          'glove_clients': _gloves.length,
          'blackout': _blackout,
          'flaky_wifi': flakyWifi,
          'pilot': pilot.name,
          'pilot_step': pilot.stepLabel,
          'log': _log.reversed.take(12).toList(),
        }));
      case '/api/scenario':
        final name = req.uri.queryParameters['name'] ?? '';
        final ok = runScenario(name);
        req.response.statusCode = ok ? HttpStatus.ok : HttpStatus.badRequest;
        req.response.write(ok ? 'ok' : 'bilinmeyen senaryo: $name');
      default:
        req.response.statusCode = HttpStatus.notFound;
    }
    await req.response.close();
  }

  void _onApp(WebSocket ws) {
    _apps.add(ws);
    _say('Uygulama bağlandı (${_apps.length})');
    ws.add(jsonEncode({'type': 'hello', 'proto': 1, 'device': 'CDTP-ROBOT-SIM', 'fw': '0.1.0-sim'}));
    ws.add(jsonEncode(robot.telemetry()));
    ws.listen(
      (data) {
        final m = _decode(data);
        if (m == null) return;
        switch (m['type']) {
          case 'ping':
            ws.add(jsonEncode({'type': 'pong', 'id': m['id']}));
          case 'test':
            _say('Uygulama: test ${m['action']} · ${m['task']}');
          case 'move' || 'cmd':
            _say('Reddedildi: uygulama hareket komutu gönderemez (şartname 5.1)');
        }
      },
      onDone: () {
        _apps.remove(ws);
        _say('Uygulama ayrıldı (${_apps.length})');
      },
    );
  }

  void _onGlove(WebSocket ws) {
    _gloves.add(ws);
    _say('Eldiven bağlandı');
    ws.listen(
      (data) {
        final m = _decode(data);
        if (m == null || m['type'] != 'glove_cmd') return;
        final cmd = m['cmd'];
        if (cmd is String && const {'forward', 'backward', 'left', 'right', 'stop'}.contains(cmd)) {
          if (pilot.active) {
            pilot.stop();
            _say('Pilot durdu: eldiven devraldı');
          }
          final repeat = cmd == robot.lastCmd && robot.state != 'balancing';
          robot.command(cmd);
          _broadcast({'type': 'event', 'name': 'glove_command', 'value': cmd});
          if (!repeat) _say('Eldiven: $cmd'); // basılı tutmada tekrarları yazma
        }
      },
      onDone: () {
        _gloves.remove(ws);
        _say('Eldiven ayrıldı');
      },
    );
  }

  Map<String, dynamic>? _decode(Object? data) {
    if (data is! String) return null;
    try {
      final j = jsonDecode(data);
      return j is Map<String, dynamic> ? j : null;
    } on FormatException {
      return null;
    }
  }

  /// Kontrol sayfasındaki senaryolar.
  bool runScenario(String name) {
    if (Autopilot.scenarios.containsKey(name)) {
      if (!pilot.start(name)) return false;
      _say('Pilot başladı: ${Autopilot.scenarios[name]}');
      return true;
    }
    switch (name) {
      case 'reset':
        pilot.stop();
        robot.reset();
      case 'auto_stop':
        pilot.stop();
        robot.command('stop');
      case 'drop_box':
        robot.dropBox();
      case 'push':
        robot.push(12);
      case 'fall':
        pilot.stop();
        robot.knockOver();
      case 'blackout_3s':
        _blackoutUntil = DateTime.now().add(const Duration(seconds: 3));
      case 'toggle_visible':
        robot.visible = !robot.visible;
      case 'flaky_wifi':
        flakyWifi = !flakyWifi;
      case 'battery_low':
        robot.batteryPct = 19;
      case 'battery_full':
        robot.batteryPct = 100;
      default:
        return false;
    }
    _say('Senaryo: $name');
    return true;
  }
}
