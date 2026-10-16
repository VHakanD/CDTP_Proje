import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_scope.dart';
import 'data/repositories/report_repository.dart';
import 'data/repositories/robot_repository.dart';
import 'data/repositories/tracking_repository.dart';
import 'data/services/report_file_service.dart';
import 'data/services/robot_socket_service.dart';
import 'dev_preset.dart';
import 'router.dart';
import 'ui/core/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Telefon dönerse işaret koordinatları kayar; web bunu yok sayar.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final robot = RobotRepository(RobotSocketService());
  final session = SessionStore();
  if (kIsWeb) DevPreset.apply(Uri.base, robot, session); // ?demo=B gibi önizleme ayarı
  runApp(AppScope(
    robot: robot,
    reports: ReportRepository(ReportFileService()),
    session: session,
    tracking: TrackingRepository(robot),
    child: CdtpMonitorApp(router: buildRouter()),
  ));
}
