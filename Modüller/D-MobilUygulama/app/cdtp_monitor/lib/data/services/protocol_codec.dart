import 'dart:convert';

import '../../domain/models/telemetry.dart';
import '../../domain/models/test_task.dart';

/// JSON ⇄ [RobotMessage]. Bozuk mesajlar `null` döner, uygulama çökmez.
abstract final class ProtocolCodec {
  static RobotMessage? decode(String raw) {
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    final type = json['type'];
    if (type is! String) return null;

    try {
      return switch (type) {
        'hello' => Hello(
            device: (json['device'] as String?) ?? 'robot',
            firmware: json['fw'] as String?,
          ),
        'telemetry' => Telemetry(
            batteryPct: _num(json['battery_pct']),
            tiltDeg: _num(json['tilt_deg']),
            charging: json['charging'] as bool,
            seq: (json['seq'] as num?)?.toInt(),
            docked: json['docked'] as bool?,
            state: json['state'] as String?,
            boxPresent: json['box_present'] as bool?,
            lastCmd: json['last_cmd'] as String?,
          ),
        'event' => RobotEvent(
            name: json['name'] as String,
            value: json['value']?.toString(),
          ),
        'pong' => Pong((json['id'] as num).toInt()),
        'sim_pose' => SimPose(
            xM: _num(json['x_m']),
            yM: _num(json['y_m']),
            headingDeg: _num(json['heading_deg']),
            visible: (json['visible'] as bool?) ?? true,
          ),
        _ => UnknownMessage(type),
      };
    } on TypeError {
      return null; // zorunlu alan eksik ya da tipi yanlış
    }
  }

  static double _num(Object? v) {
    if (v is num && v.isFinite) return v.toDouble();
    throw TypeError();
  }

  static String encodeHello(String appVersion) =>
      jsonEncode({'type': 'hello', 'proto': 1, 'client': 'cdtp-monitor', 'app_version': appVersion});

  static String encodePing(int id) => jsonEncode({'type': 'ping', 'id': id});

  static String encodeTestEvent(String action, TaskKind task, String testId) =>
      jsonEncode({'type': 'test', 'action': action, 'task': task.name, 'test_id': testId});
}
