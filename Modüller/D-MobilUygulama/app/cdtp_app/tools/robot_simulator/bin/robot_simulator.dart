// CDTP robot simulatoru.
//
// ESP32 hazir olana kadar uygulamayi test etmek icin robotun ag tarafini taklit eder.
// - ws://<host>:8765/ws  : Uygulamanin baglandigi WebSocket (protokol v1, docs/PROTOCOL.md)
// - http://<host>:8765/  : Senaryo kontrol sayfasi (dengede dur, hareket et, dock, dus, kopma ...)
//
// Calistirma:  dart run bin/robot_simulator.dart   (veya docker compose up simulator)
// Bagimlilik yok, sadece dart:io kullanir.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Robotun simule edilen anlik durumu. Gercek robotta bu degerler sensorlerden gelir.
class RobotState {
  double batteryPct = 82.0;
  double batteryV = 12.1;
  double tiltDeg = 0.0;
  bool charging = false;
  bool docked = false;
  bool boxPresent = true;
  bool irDetected = false;
  String state = 'balancing';
  String? lastCmd;
  int lastCmdSeq = 0;

  /// Bu tarihe kadar telemetri gonderilmez (baglanti kopmasi testi).
  DateTime? silentUntil;

  /// Dusme senaryosunda egimin hedef degeri.
  double? forcedTilt;
}

final _rand = Random();
final _robot = RobotState();
final _clients = <WebSocket>{};
final _startedAt = DateTime.now();
int _seq = 0;
Timer? _actionTimer;

int get _uptimeMs => DateTime.now().difference(_startedAt).inMilliseconds;

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8765;
  final hz = double.tryParse(Platform.environment['TELEMETRY_HZ'] ?? '') ?? 1.0;

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('[sim] WebSocket : ws://0.0.0.0:$port/ws');
  stdout.writeln('[sim] Kontrol   : http://localhost:$port/');

  // 1 Hz telemetri dongusu (sartname: sarj + egim 1 Hz).
  Timer.periodic(Duration(milliseconds: (1000 / hz).round()), (_) => _tick());

  await for (final request in server) {
    _handleHttp(request);
  }
}

Future<void> _handleHttp(HttpRequest req) async {
  final path = req.uri.path;
  if (path == '/ws' && WebSocketTransformer.isUpgradeRequest(req)) {
    final ws = await WebSocketTransformer.upgrade(req);
    _onClient(ws);
    return;
  }
  if (path == '/control') {
    final action = req.uri.queryParameters['action'] ?? '';
    final ok = _applyAction(action);
    req.response.headers.contentType = ContentType.json;
    req.response.headers.add('Access-Control-Allow-Origin', '*');
    req.response.write(jsonEncode({'ok': ok, 'action': action, 'state': _snapshot()}));
    await req.response.close();
    return;
  }
  if (path == '/' || path == '/index.html') {
    req.response.headers.contentType = ContentType.html;
    req.response.write(_controlPage);
    await req.response.close();
    return;
  }
  req.response.statusCode = HttpStatus.notFound;
  await req.response.close();
}

void _onClient(WebSocket ws) {
  _clients.add(ws);
  stdout.writeln('[sim] istemci baglandi (${_clients.length})');
  // Baglanti kurulunca robot kendini tanitir.
  ws.add(jsonEncode({'type': 'hello', 'proto': 1, 'device': 'CDTP-ROBOT-SIM', 'fw': 'sim-1.0'}));
  ws.listen(
    (data) {
      if (data is! String) return;
      final msg = jsonDecode(data) as Map<String, dynamic>;
      switch (msg['type']) {
        case 'ping':
          // Gidis-donus suresi (RTT) olcumu icin aninda pong.
          ws.add(jsonEncode({'type': 'pong', 'id': msg['id']}));
        case 'test':
          stdout.writeln('[sim] test isareti: ${msg['action']} ${msg['task']}');
        case 'hello':
          stdout.writeln('[sim] uygulama: ${msg['client']} proto=${msg['proto']}');
      }
    },
    onDone: () {
      _clients.remove(ws);
      stdout.writeln('[sim] istemci ayrildi (${_clients.length})');
    },
    onError: (_) => _clients.remove(ws),
  );
}

/// Her periyotta robot durumunu biraz degistirip telemetri gonderir.
void _tick() {
  final r = _robot;

  // Egim: dengede kucuk gurultu, hareket ederken biraz daha buyuk.
  final noise = switch (r.state) {
    'moving' || 'turning' => 3.0,
    'recovering' => 6.0,
    'docked' => 0.2,
    _ => 1.2,
  };
  if (r.forcedTilt != null) {
    r.tiltDeg += (r.forcedTilt! - r.tiltDeg) * 0.6;
  } else {
    r.tiltDeg = r.tiltDeg * 0.4 + (_rand.nextDouble() * 2 - 1) * noise;
  }

  // Batarya: sarjda artar, degilse yavasca azalir.
  if (r.charging) {
    r.batteryPct = min(100, r.batteryPct + 0.15);
  } else {
    r.batteryPct = max(0, r.batteryPct - 0.02);
  }
  r.batteryV = 10.5 + 2.1 * (r.batteryPct / 100);

  if (r.silentUntil != null && DateTime.now().isBefore(r.silentUntil!)) return;
  r.silentUntil = null;

  final msg = jsonEncode({
    'type': 'telemetry',
    'seq': _seq++,
    'uptime_ms': _uptimeMs,
    'battery_pct': double.parse(r.batteryPct.toStringAsFixed(1)),
    'battery_v': double.parse(r.batteryV.toStringAsFixed(2)),
    'tilt_deg': double.parse(r.tiltDeg.toStringAsFixed(2)),
    'charging': r.charging,
    'docked': r.docked,
    'state': r.state,
    'box_present': r.boxPresent,
    'ir_detected': r.irDetected,
    if (r.lastCmd != null) 'last_cmd': r.lastCmd,
    'last_cmd_seq': r.lastCmdSeq,
  });
  for (final c in _clients.toList()) {
    c.add(msg);
  }
}

void _gloveCommand(String cmd) {
  _robot.lastCmd = cmd;
  _robot.lastCmdSeq++;
  final ev = jsonEncode({'type': 'event', 'name': 'glove_command', 'value': cmd, 'uptime_ms': _uptimeMs});
  for (final c in _clients.toList()) {
    c.add(ev);
  }
}

/// Kontrol sayfasindan gelen senaryo komutlari.
bool _applyAction(String action) {
  final r = _robot;
  _actionTimer?.cancel();
  switch (action) {
    case 'balance':
      r
        ..state = 'balancing'
        ..forcedTilt = null;
    case 'forward' || 'backward':
      _gloveCommand(action);
      r.state = 'moving';
      _actionTimer = Timer(const Duration(seconds: 3), () => r.state = 'balancing');
    case 'left' || 'right':
      _gloveCommand(action);
      r.state = 'turning';
      _actionTimer = Timer(const Duration(seconds: 2), () => r.state = 'balancing');
    case 'stop':
      _gloveCommand('stop');
      r.state = 'balancing';
    case 'dock':
      // Gercekci akis: IR algilanir -> yaklasir -> yerlesir -> 2 s sonra sarj baslar.
      r
        ..irDetected = true
        ..state = 'docking';
      _actionTimer = Timer(const Duration(seconds: 3), () {
        r
          ..docked = true
          ..state = 'docked';
        _actionTimer = Timer(const Duration(seconds: 2), () => r.charging = true);
      });
    case 'undock':
      r
        ..docked = false
        ..charging = false
        ..irDetected = false
        ..state = 'balancing';
    case 'fall':
      r
        ..forcedTilt = 75
        ..state = 'fallen';
    case 'tilt_recover':
      // +10 derece itme sonrasi toparlanma.
      r
        ..tiltDeg = 10
        ..forcedTilt = null
        ..state = 'recovering';
      _actionTimer = Timer(const Duration(seconds: 3), () => r.state = 'balancing');
    case 'box_drop':
      r.boxPresent = false;
    case 'box_place':
      r.boxPresent = true;
    case 'dropout':
      // 3 s boyunca telemetri gonderme: uygulamanin 2 s kopma uyarisini test eder.
      r.silentUntil = DateTime.now().add(const Duration(seconds: 3));
    case 'battery_low':
      r.batteryPct = 12;
    default:
      return false;
  }
  stdout.writeln('[sim] eylem: $action');
  return true;
}

Map<String, Object?> _snapshot() => {
      'battery_pct': _robot.batteryPct,
      'tilt_deg': _robot.tiltDeg,
      'charging': _robot.charging,
      'docked': _robot.docked,
      'state': _robot.state,
      'box_present': _robot.boxPresent,
      'clients': _clients.length,
    };

const _controlPage = '''
<!doctype html><html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>CDTP Robot Simulatoru</title>
<style>
 body{font-family:system-ui,sans-serif;background:#F3F6F8;color:#1C2A36;margin:24px}
 h1{font-size:20px} h2{font-size:14px;color:#3E5C76;margin:20px 0 8px}
 button{background:#3E5C76;color:#fff;border:0;border-radius:6px;padding:10px 14px;margin:4px;cursor:pointer}
 button.t{background:#1A9E9E} button.w{background:#C8553D}
 pre{background:#fff;border:1px solid #D5DEE5;border-radius:6px;padding:12px}
</style></head><body>
<h1>CDTP Robot Simulatoru</h1>
<h2>Denge</h2>
<button onclick="a('balance')">Dengede dur</button>
<button onclick="a('tilt_recover')">+10 derece toparlanma</button>
<button class="w" onclick="a('fall')">Dus</button>
<h2>Eldiven komutu</h2>
<button class="t" onclick="a('forward')">Ileri</button>
<button class="t" onclick="a('backward')">Geri</button>
<button class="t" onclick="a('left')">Sola</button>
<button class="t" onclick="a('right')">Saga</button>
<button class="t" onclick="a('stop')">Dur</button>
<h2>Sarj istasyonu</h2>
<button onclick="a('dock')">Istasyona yerles</button>
<button onclick="a('undock')">Istasyondan cek</button>
<button onclick="a('battery_low')">Batarya %12</button>
<h2>Yuk ve baglanti</h2>
<button class="w" onclick="a('box_drop')">Kutu dustu</button>
<button onclick="a('box_place')">Kutu yerinde</button>
<button class="w" onclick="a('dropout')">3 s baglanti kes</button>
<pre id="o">-</pre>
<script>
async function a(x){const r=await fetch('/control?action='+x);document.getElementById('o').textContent=JSON.stringify(await r.json(),null,2);}
</script></body></html>
''';
