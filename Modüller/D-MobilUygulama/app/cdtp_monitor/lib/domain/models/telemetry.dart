/// Robottan (ESP32-S3) gelen mesajlar. Protokol v1 ile uyumlu;
/// bkz. `docs/ARCHITECTURE.md` → Protokol.
sealed class RobotMessage {
  const RobotMessage();
}

class Hello extends RobotMessage {
  const Hello({required this.device, this.firmware});
  final String device;
  final String? firmware;
}

/// 1 Hz telemetri. Zorunlu alanlar: pil, eğim, şarj.
class Telemetry extends RobotMessage {
  const Telemetry({
    required this.batteryPct,
    required this.tiltDeg,
    required this.charging,
    this.seq,
    this.docked,
    this.state,
    this.boxPresent,
    this.lastCmd,
  });

  final double batteryPct;
  final double tiltDeg;
  final bool charging;
  final int? seq;
  final bool? docked;

  /// `idle`, `balancing`, `moving`, `turning`, `recovering`, `docking`,
  /// `docked`, `fallen`.
  final String? state;
  final bool? boxPresent;
  final String? lastCmd;

  bool get fallen => state == 'fallen' || tiltDeg.abs() > 45;
}

class RobotEvent extends RobotMessage {
  const RobotEvent({required this.name, this.value});
  final String name;
  final String? value;
}

class Pong extends RobotMessage {
  const Pong(this.id);
  final int id;
}

/// Yalnız simülatör gönderir: robotun sahnedeki konumu (metre).
/// Gerçek robot göndermez; uygulama bunu sanal kamera sahnesi için kullanır.
class SimPose extends RobotMessage {
  const SimPose({
    required this.xM,
    required this.yM,
    required this.headingDeg,
    required this.visible,
  });
  final double xM;
  final double yM;
  final double headingDeg;
  final bool visible;
}

class UnknownMessage extends RobotMessage {
  const UnknownMessage(this.type);
  final String type;
}
