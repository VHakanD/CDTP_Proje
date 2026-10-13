import 'robot_telemetry.dart';

/// Robottan gelen mesaj turleri (protokol v1, docs/PROTOCOL.md).
sealed class RobotMessage {
  const RobotMessage();
}

/// Baglanti kurulunca robotun gonderdigi tanitim mesaji.
class HelloMessage extends RobotMessage {
  const HelloMessage({required this.device, required this.firmware, required this.protocol});
  final String device;
  final String firmware;
  final int protocol;
}

/// 1 Hz periyodik durum paketi.
class TelemetryMessage extends RobotMessage {
  const TelemetryMessage(this.telemetry);
  final RobotTelemetry telemetry;
}

/// Anlik olay (orn. eldivenden komut alindi, IR istasyon goruldu).
class EventMessage extends RobotMessage {
  const EventMessage({required this.name, this.value, required this.receivedAt});
  final String name;
  final Object? value;
  final DateTime receivedAt;
}

/// Uygulamanin ping'ine cevap (gidis-donus suresi olcumu).
class PongMessage extends RobotMessage {
  const PongMessage(this.id);
  final int id;
}

/// Taninmayan veya bozuk mesaj. Baglantiyi koparmaz, sadece sayilir.
class UnknownMessage extends RobotMessage {
  const UnknownMessage(this.raw, this.reason);
  final String raw;
  final String reason;
}
