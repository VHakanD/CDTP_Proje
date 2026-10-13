import 'package:flutter/foundation.dart';

/// Robotun kendi bildirdigi calisma durumu (protokoldeki "state" alani).
enum RobotReportedState {
  idle('Bekliyor'),
  balancing('Dengede'),
  moving('Hareket ediyor'),
  turning('Dönüyor'),
  recovering('Toparlanıyor'),
  docking('İstasyona yaklaşıyor'),
  docked('İstasyonda'),
  fallen('Düştü'),
  unknown('Bilinmiyor');

  const RobotReportedState(this.label);
  final String label;

  static RobotReportedState? parse(Object? raw) {
    if (raw is! String) return null;
    return RobotReportedState.values.asNameMap()[raw] ?? RobotReportedState.unknown;
  }
}

/// Eldivenden robota giden bes komut (sartname Modul B).
/// Uygulama bu komutlari robota GONDERMEZ; robot aldigi son komutu bildirirse gosterir.
enum GloveCommand {
  forward('İleri'),
  backward('Geri'),
  left('Sola dön'),
  right('Sağa dön'),
  stop('Dur');

  const GloveCommand(this.label);
  final String label;

  static GloveCommand? parse(Object? raw) =>
      raw is String ? GloveCommand.values.asNameMap()[raw] : null;
}

/// Robottan 1 Hz ile gelen telemetri paketi.
///
/// Zorunlu alanlar: battery_pct, tilt_deg, charging.
/// Diger alanlar opsiyoneldir; robotta ilgili sensor yoksa null kalir ve
/// arayuzde "—" olarak gorunur.
@immutable
class RobotTelemetry {
  const RobotTelemetry({
    required this.receivedAt,
    this.seq,
    this.uptimeMs,
    this.batteryPct,
    this.batteryV,
    this.tiltDeg,
    this.charging,
    this.docked,
    this.state,
    this.boxPresent,
    this.irDetected,
    this.lastCommand,
    this.lastCommandSeq,
  });

  /// Telefonun mesaji aldigi an (olcumler bu zamana gore yapilir).
  final DateTime receivedAt;
  final int? seq;
  final int? uptimeMs;
  final double? batteryPct;
  final double? batteryV;
  final double? tiltDeg;

  /// Donanimsal CHG/STAT sinyalinin robot tarafindan okunan degeri.
  final bool? charging;
  final bool? docked;
  final RobotReportedState? state;
  final bool? boxPresent;
  final bool? irDetected;
  final GloveCommand? lastCommand;
  final int? lastCommandSeq;

  factory RobotTelemetry.fromJson(Map<String, Object?> j, DateTime receivedAt) {
    double? d(String k) => (j[k] as num?)?.toDouble();
    int? i(String k) => (j[k] as num?)?.toInt();
    bool? b(String k) => j[k] is bool ? j[k] as bool : null;
    return RobotTelemetry(
      receivedAt: receivedAt,
      seq: i('seq'),
      uptimeMs: i('uptime_ms'),
      batteryPct: d('battery_pct'),
      batteryV: d('battery_v'),
      tiltDeg: d('tilt_deg'),
      charging: b('charging'),
      docked: b('docked'),
      state: RobotReportedState.parse(j['state']),
      boxPresent: b('box_present'),
      irDetected: b('ir_detected'),
      lastCommand: GloveCommand.parse(j['last_cmd']),
      lastCommandSeq: i('last_cmd_seq'),
    );
  }

  /// Rapora yazilan bicim (robot protokoluyle ayni anahtar isimleri + alinma zamani).
  Map<String, Object?> toJson() => {
        'received_at': receivedAt.toUtc().toIso8601String(),
        if (seq != null) 'seq': seq,
        if (uptimeMs != null) 'uptime_ms': uptimeMs,
        if (batteryPct != null) 'battery_pct': batteryPct,
        if (batteryV != null) 'battery_v': batteryV,
        if (tiltDeg != null) 'tilt_deg': tiltDeg,
        if (charging != null) 'charging': charging,
        if (docked != null) 'docked': docked,
        if (state != null) 'state': state!.name,
        if (boxPresent != null) 'box_present': boxPresent,
        if (irDetected != null) 'ir_detected': irDetected,
        if (lastCommand != null) 'last_cmd': lastCommand!.name,
        if (lastCommandSeq != null) 'last_cmd_seq': lastCommandSeq,
      };

  factory RobotTelemetry.fromStoredJson(Map<String, Object?> j) =>
      RobotTelemetry.fromJson(j, DateTime.parse(j['received_at']! as String));
}
