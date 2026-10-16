import 'package:cdtp_monitor/app_scope.dart';
import 'package:cdtp_monitor/data/repositories/report_repository.dart';
import 'package:cdtp_monitor/data/repositories/robot_repository.dart';
import 'package:cdtp_monitor/data/repositories/tracking_repository.dart';
import 'package:cdtp_monitor/data/services/report_file_service.dart';
import 'package:cdtp_monitor/data/services/robot_socket_service.dart';
import 'package:cdtp_monitor/data/services/sim_glove_service.dart';
import 'package:cdtp_monitor/ui/core/session_store.dart';
import 'package:cdtp_monitor/ui/core/widgets/sim_glove_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ağsız eldiven: bağlı sayılır, gönderilen komutları kaydeder.
class FakeGlove extends SimGloveService {
  FakeGlove() {
    connected.value = true;
  }
  final sent = <String>[];

  @override
  Future<void> attach(Uri robot) async {}
  @override
  Future<void> detach() async {}
  @override
  void send(String cmd) => sent.add(cmd);
}

Widget gloveApp(SimGloveService glove) {
  final robot = RobotRepository(RobotSocketService());
  return AppScope(
    robot: robot,
    reports: ReportRepository(MemoryReportFileService()),
    session: SessionStore(),
    tracking: TrackingRepository(robot),
    // Anahtar: her sahte eldiven yeni bir State alsın (servis initState'te bağlanır).
    child: MaterialApp(home: SimGloveLayer(key: ObjectKey(glove), service: glove, child: const Scaffold())),
  );
}

void main() {
  test('glove_uri_is_derived_from_robot_uri', () {
    expect(SimGloveService.gloveUriFor(Uri.parse('ws://localhost:8765/ws')).toString(), 'ws://localhost:8765/glove');
    expect(SimGloveService.gloveUriFor(Uri.parse('ws://10.0.2.2:8765/ws?x=1')).toString(), 'ws://10.0.2.2:8765/glove');
  });

  test('send_without_connection_is_noop', () {
    final g = SimGloveService()..send('forward');
    expect(g.lastCmd.value, isNull);
    expect(g.connected.value, isFalse);
  });

  testWidgets('keys_send_glove_commands', (t) async {
    const pairs = {
      'forward': LogicalKeyboardKey.keyW,
      'backward': LogicalKeyboardKey.keyS,
      'left': LogicalKeyboardKey.keyA,
      'right': LogicalKeyboardKey.keyD,
      'stop': LogicalKeyboardKey.space,
    };
    for (final MapEntry(key: cmd, value: key) in pairs.entries) {
      final glove = FakeGlove();
      await t.pumpWidget(gloveApp(glove));
      await t.sendKeyEvent(key);
      await t.pump();
      expect(glove.sent, [cmd], reason: 'klavye: $cmd');
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5)); // rozet zamanlayıcıları
  });

  // Şartname 5.1: komutlar yalnız eldivenden; uygulamada dokunulabilir sürüş düğmesi olmamalı.
  testWidgets('no_on_screen_drive_controls', (t) async {
    final glove = FakeGlove();
    await t.pumpWidget(gloveApp(glove));
    await t.sendKeyEvent(LogicalKeyboardKey.keyW);
    await t.pump();
    expect(glove.sent, ['forward']);
    // Rozet de yok: yön, kamera ekranındaki yön göstergesinden okunur.
    expect(find.textContaining('sanal eldiven'), findsNothing);
    for (final glyph in ['▲', '▼', '◀', '▶', '■']) {
      expect(find.text(glyph), findsNothing, reason: glyph);
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
