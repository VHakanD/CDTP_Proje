import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'glove_client.dart';
import 'server.dart';

final parser = ArgParser()
  ..addOption('port', abbr: 'p', defaultsTo: '8765', help: 'Robot simülatörünün portu.')
  ..addOption('hz', defaultsTo: '1', help: 'Telemetri sıklığı (şartname: 1 Hz).')
  ..addOption('glove', help: 'Eldiven modu: robot adresine bağlan, ör. ws://localhost:8765/glove')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Yardım.');

/// Çıkış kodu döner (0 başarı, 64 kullanım hatası).
Future<int> runCli(List<String> args) async {
  final ArgResults r;
  try {
    r = parser.parse(args);
  } on FormatException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln(parser.usage);
    return 64;
  }
  if (r.flag('help')) {
    stdout
      ..writeln('Kullanım: dart run esp32_sim [--port 8765] [--hz 1] | --glove <url>')
      ..writeln(parser.usage);
    return 0;
  }

  final glove = r.option('glove');
  if (glove != null) return GloveClient(Uri.parse(glove)).run();

  final port = int.tryParse(r.option('port')!);
  final hz = double.tryParse(r.option('hz')!);
  if (port == null || hz == null || hz <= 0) {
    stderr
      ..writeln('--port ve --hz sayı olmalı')
      ..writeln(parser.usage);
    return 64;
  }

  final server = SimServer(port: port, telemetryHz: hz);
  await server.start();
  final done = Completer<void>();
  final subs = [
    ProcessSignal.sigint.watch().listen((_) => done.complete()),
    if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen((_) => done.complete()),
  ];
  await done.future;
  for (final s in subs) {
    await s.cancel();
  }
  await server.stop();
  stdout.writeln('Simülatör kapandı.');
  return 0;
}
