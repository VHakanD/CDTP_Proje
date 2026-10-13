import 'package:cdtp_robot_app/features/connection/data/protocol_codec.dart';
import 'package:cdtp_robot_app/features/connection/domain/robot_message.dart';
import 'package:cdtp_robot_app/features/connection/domain/robot_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = ProtocolCodec();

  test('telemetri paketi cozulur', () {
    final msg = codec.decode(
      '{"type":"telemetry","seq":5,"battery_pct":78.5,"tilt_deg":-1.4,"charging":true,'
      '"docked":true,"state":"docked","box_present":true,"last_cmd":"left"}',
    );
    expect(msg, isA<TelemetryMessage>());
    final t = (msg as TelemetryMessage).telemetry;
    expect(t.seq, 5);
    expect(t.batteryPct, 78.5);
    expect(t.tiltDeg, -1.4);
    expect(t.charging, isTrue);
    expect(t.docked, isTrue);
    expect(t.state, RobotReportedState.docked);
    expect(t.lastCommand, GloveCommand.left);
  });

  test('opsiyonel alanlar yoksa null kalir', () {
    final t = (codec.decode('{"type":"telemetry","battery_pct":50,"tilt_deg":0,"charging":false}')
            as TelemetryMessage)
        .telemetry;
    expect(t.batteryPct, 50.0);
    expect(t.docked, isNull);
    expect(t.boxPresent, isNull);
    expect(t.state, isNull);
  });

  test('bilinmeyen durum degeri unknown olur', () {
    final t = (codec.decode('{"type":"telemetry","state":"dancing"}') as TelemetryMessage).telemetry;
    expect(t.state, RobotReportedState.unknown);
  });

  test('hello ve pong cozulur', () {
    final hello = codec.decode('{"type":"hello","device":"CDTP-ROBOT","fw":"1.0","proto":1}');
    expect(hello, isA<HelloMessage>());
    expect((hello as HelloMessage).device, 'CDTP-ROBOT');
    final pong = codec.decode('{"type":"pong","id":7}');
    expect((pong as PongMessage).id, 7);
  });

  test('bozuk JSON baglantiyi koparmaz, UnknownMessage doner', () {
    expect(codec.decode('{bozuk'), isA<UnknownMessage>());
    expect(codec.decode('[1,2]'), isA<UnknownMessage>());
    expect(codec.decode('{"type":"x"}'), isA<UnknownMessage>());
  });

  test('alan tipi yanlissa hata firlatmaz, UnknownMessage doner', () {
    expect(codec.decode('{"type":"telemetry","battery_pct":"abc"}'), isA<UnknownMessage>());
    expect(codec.decode('{"type":"hello","device":5}'), isA<UnknownMessage>());
  });

  test('telemetri rapora yazilip geri okunabilir', () {
    final now = DateTime.utc(2026, 10, 13, 12);
    final t = (codec.decode('{"type":"telemetry","battery_pct":60,"tilt_deg":2.5,"charging":false}',
            now: now) as TelemetryMessage)
        .telemetry;
    final back = RobotTelemetry.fromStoredJson(t.toJson());
    expect(back.receivedAt, now);
    expect(back.tiltDeg, 2.5);
  });
}
