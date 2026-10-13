import 'dart:convert';

import '../../../core/config/app_constants.dart';
import '../domain/robot_message.dart';
import '../domain/robot_telemetry.dart';

/// JSON metni <-> RobotMessage donusumu (protokol v1).
///
/// Hem Wi-Fi hem BLE ayni kodlayiciyi kullanir; boylece ESP32 tarafinda tek bir
/// mesaj formati yazmak yeterlidir.
class ProtocolCodec {
  const ProtocolCodec();

  /// Robottan gelen tek bir JSON metnini cozer. Hata firlatmaz.
  RobotMessage decode(String raw, {DateTime? now}) {
    final receivedAt = now ?? DateTime.now();
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      return UnknownMessage(raw, 'JSON hatası: ${e.message}');
    }
    if (decoded is! Map) return UnknownMessage(raw, 'JSON nesnesi değil');
    final j = decoded.cast<String, Object?>();

    // Alan tipleri yanlissa (orn. "battery_pct":"abc") cast hatasi baglantiyi bozmasin.
    try {
      return _dispatch(j, raw, receivedAt);
    } catch (e) {
      return UnknownMessage(raw, 'Alan tipi hatalı: $e');
    }
  }

  RobotMessage _dispatch(Map<String, Object?> j, String raw, DateTime receivedAt) {
    switch (j['type']) {
      case 'telemetry':
        return TelemetryMessage(RobotTelemetry.fromJson(j, receivedAt));
      case 'hello':
        return HelloMessage(
          device: j['device'] as String? ?? 'bilinmiyor',
          firmware: j['fw'] as String? ?? '-',
          protocol: (j['proto'] as num?)?.toInt() ?? 0,
        );
      case 'event':
        return EventMessage(
          name: j['name'] as String? ?? 'event',
          value: j['value'],
          receivedAt: receivedAt,
        );
      case 'pong':
        return PongMessage((j['id'] as num?)?.toInt() ?? -1);
      default:
        return UnknownMessage(raw, 'Bilinmeyen tür: ${j['type']}');
    }
  }

  // ---- Uygulamadan robota giden mesajlar ----
  // Not: Sartname geregi uygulama robota HAREKET komutu gondermez.

  String hello() => jsonEncode({
        'type': 'hello',
        'proto': AppConstants.protocolVersion,
        'client': 'cdtp-app',
        'app_version': AppConstants.appVersion,
      });

  String ping(int id) => jsonEncode({'type': 'ping', 'id': id});

  /// Test basladi/bitti bilgisi. Robot isterse kendi kaydina isaret koyar.
  String testMarker({required String action, required String task, required String testId}) =>
      jsonEncode({'type': 'test', 'action': action, 'task': task, 'test_id': testId});
}
