import 'dart:io';

import 'package:esp32_sim/src/cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args);
}
