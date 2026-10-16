import 'package:flutter/widgets.dart';

import 'data/repositories/report_repository.dart';
import 'data/repositories/robot_repository.dart';
import 'data/repositories/tracking_repository.dart';
import 'ui/core/session_store.dart';

/// Bağımlılıkları ağaca verir (harici DI paketi yok).
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.robot,
    required this.reports,
    required this.session,
    required this.tracking,
    required super.child,
  });

  final RobotRepository robot;
  final ReportRepository reports;
  final SessionStore session;
  final TrackingRepository tracking;

  static AppScope of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(s != null, 'AppScope bulunamadı');
    return s!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      robot != old.robot || reports != old.reports || session != old.session || tracking != old.tracking;
}
