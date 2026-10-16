import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:esp32_sim/src/autopilot.dart';
import 'package:esp32_sim/src/glove_client.dart';
import 'package:esp32_sim/src/robot_model.dart';
import 'package:esp32_sim/src/server.dart';
import 'package:test/test.dart';

void run(RobotModel r, double seconds) {
  for (var t = 0.0; t < seconds; t += 0.02) {
    r.step(0.02);
  }
}

void main() {
  group('RobotModel', () {
    test('forward_moves_half_meter', () {
      final r = RobotModel()..command('forward');
      run(r, 1.0);
      expect(r.state, 'moving');
      run(r, 1.5);
      expect(r.y, closeTo(0.5, 0.01));
      expect(r.state, 'balancing');
    });

    test('right_turn_is_90_degrees', () {
      final r = RobotModel()..command('right');
      run(r, 1.5);
      expect(r.headingDeg, closeTo(90, 0.5));
      r.command('forward');
      run(r, 2.5);
      expect(r.x, closeTo(0.5, 0.01));
    });

    test('dock_then_charge_within_5s', () {
      final r = RobotModel()..dock();
      run(r, 6.6); // 1,2 m / 0,2 m/s = 6 s + hızlanma/yavaşlama
      expect(r.docked, isTrue);
      run(r, 2.1);
      expect(r.charging, isTrue);
      expect(r.telemetry()['charging'], isTrue);
    });

    test('telemetry_has_required_fields', () {
      final t = RobotModel().telemetry();
      expect(t['type'], 'telemetry');
      expect(t['battery_pct'], isA<double>());
      expect(t['tilt_deg'], isA<double>());
      expect(t['charging'], isA<bool>());
      expect(t.containsKey('last_cmd'), isFalse); // yoksa gönderilmez
    });
  });

  group('Gerçekçi hareket', () {
    test('accelerates_then_brakes', () {
      final r = RobotModel()..command('forward');
      run(r, 0.1);
      expect(r.speed, inInclusiveRange(0.05, 0.15)); // hemen tam hıza çıkmaz
      run(r, 0.6);
      expect(r.speed, closeTo(RobotModel.speedMps, 1e-6));
      expect(r.tiltDeg, greaterThan(1)); // ileri sürerken öne yatık
    });

    test('held_forward_drives_continuously_and_stop_brakes', () {
      final r = RobotModel();
      for (var i = 0; i < 20; i++) {
        r.command('forward'); // basılı tutma: 200 ms'de bir tekrar
        run(r, 0.2);
      }
      expect(r.y, greaterThan(0.85)); // 4 s × 0,25 m/s ≈ 1 m (kalkış hariç)
      r.command('stop');
      final y0 = r.y;
      run(r, 1.0);
      expect(r.y - y0, inInclusiveRange(0.01, 0.06)); // fren mesafesi ≈ 3 cm
      expect(r.state, 'balancing');
    });

    test('battery_drains_faster_when_moving', () {
      final idle = RobotModel();
      final busy = RobotModel();
      for (var i = 0; i < 50; i++) {
        busy.command('forward');
        run(busy, 0.2);
        run(idle, 0.2);
      }
      expect(RobotModel.startBatteryPct - busy.batteryPct,
          greaterThan((RobotModel.startBatteryPct - idle.batteryPct) * 2));
    });
  });

  group('Autopilot', () {
    void fly(Autopilot p, double seconds) {
      for (var t = 0.0; t < seconds && p.active; t += 0.02) {
        p.robot.step(0.02);
        p.tick(0.02);
      }
    }

    test('task_B_forward_ends_near_one_meter', () {
      final p = Autopilot(RobotModel(), random: math.Random(1))..start('auto_B_forward');
      fly(p, 20);
      expect(p.active, isFalse);
      expect(p.robot.y, inInclusiveRange(0.9, 1.1));
      expect(p.robot.x.abs(), lessThan(0.01));
    });

    test('task_B_right_moves_sideways', () {
      final p = Autopilot(RobotModel(), random: math.Random(2))..start('auto_B_right');
      fly(p, 20);
      expect(p.robot.x, inInclusiveRange(0.9, 1.1));
      expect(p.robot.y.abs(), lessThan(0.05));
    });

    test('task_C_and_E_end_charging', () {
      for (final s in ['auto_C', 'auto_E']) {
        final p = Autopilot(RobotModel(), random: math.Random(3))..start(s);
        fly(p, 40);
        expect(p.active, isFalse, reason: s);
        expect(p.robot.charging, isTrue, reason: s);
      }
    });

    test('task_A_stays_still_30s', () {
      final p = Autopilot(RobotModel(), random: math.Random(4))..start('auto_A');
      fly(p, 40);
      expect(p.robot.x.abs() + p.robot.y.abs(), lessThan(1e-9));
      expect(p.robot.fallen, isFalse);
    });

    test('wander_stays_in_bounds_and_moves', () {
      final p = Autopilot(RobotModel(), random: math.Random(5))..start('wander');
      var path = 0.0;
      var (px, py) = (0.0, 0.0);
      for (var t = 0.0; t < 300; t += 0.02) {
        p.robot.step(0.02);
        p.tick(0.02);
        final r = p.robot;
        path += math.sqrt(math.pow(r.x - px, 2) + math.pow(r.y - py, 2));
        (px, py) = (r.x, r.y);
        expect(r.x.abs(), lessThan(1.6));
        expect(r.y, inInclusiveRange(-0.8, 2.3));
      }
      expect(p.active, isTrue);
      expect(path, greaterThan(5));
    });

    test('glove_command_cancels_pilot', () async {
      final server = SimServer(port: 0);
      await server.start();
      addTearDown(server.stop);
      server.runScenario('wander');
      final glove = await WebSocket.connect('ws://localhost:${server.boundPort}/glove');
      glove.add(jsonEncode({'type': 'glove_cmd', 'cmd': 'left', 'seq': 1}));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(server.pilot.active, isFalse);
      await glove.close();
    });
  });

  test('glove_keys_map_to_commands', () {
    expect(GloveClient.commandForKey('W'), 'forward');
    expect(GloveClient.commandForKey(' '), 'stop');
    expect(GloveClient.commandForKey('x'), isNull);
  });

  test('server_end_to_end_hello_telemetry_glove', () async {
    final server = SimServer(port: 0, telemetryHz: 5);
    await server.start();
    addTearDown(server.stop);

    final app = await WebSocket.connect('ws://localhost:${server.boundPort}/ws');
    final msgs = app.map((e) => jsonDecode(e as String) as Map<String, dynamic>).asBroadcastStream();
    expect((await msgs.first)['type'], 'hello');

    final glove = await WebSocket.connect('ws://localhost:${server.boundPort}/glove');
    glove.add(jsonEncode({'type': 'glove_cmd', 'cmd': 'forward', 'seq': 1}));

    final moving = await msgs
        .where((m) => m['type'] == 'telemetry' && m['state'] == 'moving')
        .first
        .timeout(const Duration(seconds: 3));
    expect(moving['last_cmd'], 'forward');

    app.add(jsonEncode({'type': 'ping', 'id': 7}));
    final pong = await msgs.firstWhere((m) => m['type'] == 'pong').timeout(const Duration(seconds: 2));
    expect(pong['id'], 7);

    final page = await (await HttpClient().getUrl(Uri.parse('http://localhost:${server.boundPort}/'))).close();
    expect(page.statusCode, 200);
    await page.drain<void>();

    await glove.close();
    await app.close();
  });
}
