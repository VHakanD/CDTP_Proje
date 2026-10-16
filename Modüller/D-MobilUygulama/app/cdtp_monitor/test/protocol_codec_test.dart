import 'package:cdtp_monitor/data/services/protocol_codec.dart';
import 'package:cdtp_monitor/domain/models/link_health.dart';
import 'package:cdtp_monitor/domain/models/telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProtocolCodec', () {
    test('codec_parses_telemetry', () {
      final m = ProtocolCodec.decode(
          '{"type":"telemetry","seq":128,"battery_pct":78.5,"tilt_deg":1.42,"charging":false,"state":"balancing"}');
      expect(m, isA<Telemetry>());
      final t = m as Telemetry;
      expect(t.batteryPct, 78.5);
      expect(t.tiltDeg, 1.42);
      expect(t.charging, isFalse);
      expect(t.seq, 128);
      expect(t.docked, isNull);
    });

    test('codec_rejects_bad_json', () {
      expect(ProtocolCodec.decode('{bad'), isNull);
      expect(ProtocolCodec.decode('{"type":"telemetry","battery_pct":NaN,"tilt_deg":0,"charging":false}'), isNull);
      expect(ProtocolCodec.decode('{"type":"telemetry","tilt_deg":0,"charging":false}'), isNull);
      expect(ProtocolCodec.decode('[1,2]'), isNull);
    });

    test('codec_keeps_unknown_type', () {
      expect(ProtocolCodec.decode('{"type":"future_thing","x":1}'), isA<UnknownMessage>());
    });

    test('codec_parses_sim_pose_and_pong', () {
      final p = ProtocolCodec.decode('{"type":"sim_pose","x_m":0.1,"y_m":0.97,"heading_deg":0}') as SimPose;
      expect(p.yM, 0.97);
      expect(p.visible, isTrue);
      expect((ProtocolCodec.decode('{"type":"pong","id":42}') as Pong).id, 42);
    });
  });

  group('LinkHealth', () {
    test('health_levels', () {
      LinkLevel at(int ms) => LinkHealth.levelFor(Duration(milliseconds: ms), socketOpen: true);
      expect(at(400), LinkLevel.ok);
      expect(at(1500), LinkLevel.ok);
      expect(at(1700), LinkLevel.slow);
      expect(at(2000), LinkLevel.slow);
      expect(at(2100), LinkLevel.lost);
      expect(LinkHealth.levelFor(Duration.zero, socketOpen: false), LinkLevel.disconnected);
    });
  });
}
