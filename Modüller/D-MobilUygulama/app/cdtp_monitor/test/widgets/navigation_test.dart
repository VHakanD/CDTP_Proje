import 'package:cdtp_monitor/app.dart';
import 'package:cdtp_monitor/app_scope.dart';
import 'package:cdtp_monitor/data/repositories/report_repository.dart';
import 'package:cdtp_monitor/data/repositories/robot_repository.dart';
import 'package:cdtp_monitor/data/repositories/tracking_repository.dart';
import 'package:cdtp_monitor/data/services/report_file_service.dart';
import 'package:cdtp_monitor/data/services/robot_socket_service.dart';
import 'package:cdtp_monitor/domain/models/criterion.dart';
import 'package:cdtp_monitor/domain/models/link_health.dart';
import 'package:cdtp_monitor/domain/models/motion.dart';
import 'package:cdtp_monitor/domain/models/test_task.dart';
import 'package:cdtp_monitor/router.dart';
import 'package:cdtp_monitor/ui/core/session_store.dart';
import 'package:cdtp_monitor/ui/features/camera_hud/views/camera_hud_screen.dart';
import 'package:cdtp_monitor/ui/features/connection/views/connection_screen.dart';
import 'package:cdtp_monitor/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:cdtp_monitor/ui/features/reports/views/report_detail_screen.dart';
import 'package:cdtp_monitor/ui/features/reports/views/reports_screen.dart';
import 'package:cdtp_monitor/ui/features/result/views/result_screen.dart';
import 'package:cdtp_monitor/ui/features/tasks/views/task_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show FakeTracker, phone, unmount;

/// screens_test.dart'taki Harness'in rapor deposuna erişilebilen hâli.
class NavHarness {
  final robot = RobotRepository(RobotSocketService());
  final tracker = FakeTracker();
  final session = SessionStore();
  final reports = ReportRepository(MemoryReportFileService());
  late final tracking = TrackingRepository(robot, trackerFactory: () => tracker);

  Widget app(String initial) => AppScope(
        robot: robot,
        reports: reports,
        session: session,
        tracking: tracking,
        child: CdtpMonitorApp(router: buildRouter(initial: initial)),
      );

  Future<String> sealOne() async {
    final now = DateTime(2026, 10, 16, 12);
    final r = await reports.seal(ReportDraft(
      task: TaskKind.staticBalance,
      startedAt: now,
      endedAt: now.add(const Duration(seconds: 30)),
      criteria: const [Criterion(name: 'Süre', measured: '30 s', target: '30 s', result: CriterionResult.pass)],
      events: const [(0, 'Test başladı')],
      conditions: const {},
      telemetryCount: 30,
    ));
    return r.id;
  }
}

/// Android sistem geri tuşu.
Future<void> systemBack(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

void main() {
  testWidgets('connect_reports_back_returns_to_connect', (t) async {
    await phone(t);
    await t.pumpWidget(NavHarness().app('/connect'));
    await t.pumpAndSettle();
    await t.tap(find.text('Rapor geçmişi'));
    await t.pumpAndSettle();
    expect(find.byType(ReportsScreen), findsOneWidget);
    await systemBack(t);
    expect(find.byType(ConnectionScreen), findsOneWidget);
  });

  testWidgets('result_back_goes_to_dashboard_and_closes_tracker', (t) async {
    await phone(t);
    final h = NavHarness();
    final id = await h.sealOne();
    await h.tracking.open();
    await t.pumpWidget(h.app('/result/$id'));
    await t.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    await systemBack(t);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(h.tracking.ready, isFalse);
  });

  testWidgets('result_appbar_close_goes_to_dashboard', (t) async {
    await phone(t);
    final h = NavHarness();
    final id = await h.sealOne();
    await t.pumpWidget(h.app('/result/$id'));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.close));
    await t.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('result_open_report_back_returns_to_result', (t) async {
    await phone(t);
    final h = NavHarness();
    final id = await h.sealOne();
    await t.pumpWidget(h.app('/result/$id'));
    await t.pumpAndSettle();
    await t.tap(find.text('Raporu aç'));
    await t.pumpAndSettle();
    expect(find.byType(ReportDetailScreen), findsOneWidget);
    await systemBack(t);
    expect(find.byType(ResultScreen), findsOneWidget);
  });

  testWidgets('result_new_test_back_returns_to_dashboard', (t) async {
    await phone(t);
    final h = NavHarness();
    final id = await h.sealOne();
    await t.pumpWidget(h.app('/result/$id'));
    await t.pumpAndSettle();
    await t.tap(find.text('Yeni test'));
    await t.pumpAndSettle();
    expect(find.byType(TaskSelectScreen), findsOneWidget);
    await systemBack(t);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('dashboard_back_asks_then_disconnects', (t) async {
    await phone(t);
    final h = NavHarness();
    await h.tracking.open();
    await t.pumpWidget(h.app('/dashboard'));
    await t.pump();
    await t.binding.handlePopRoute();
    await t.pump();
    expect(find.text('Bağlantı kesilsin mi?'), findsOneWidget);
    await t.tap(find.text('Vazgeç'));
    await t.pump();
    expect(find.byType(DashboardScreen), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pump();
    await t.tap(find.text('Kes'));
    await t.pump();
    await t.pump();
    expect(find.byType(ConnectionScreen), findsOneWidget);
    expect(h.tracking.ready, isFalse);
  });

  testWidgets('hud_back_blocked_while_recording', (t) async {
    await phone(t);
    final h = NavHarness()..session.selectTask(TaskKind.staticBalance);
    h.robot.link.value = const LinkState(level: LinkLevel.ok, helloReceived: true, telemetryReceived: true);
    await t.pumpWidget(h.app('/camera'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    h.tracker.ctrl.add(TrackSample(t: h.robot.now(), center: const Offset(0.5, 0.7), confidence: 0.95));
    await t.pump();
    await t.pump();
    await t.tap(find.byKey(const Key('start-test')));
    await t.pump();
    await t.binding.handlePopRoute();
    await t.pump();
    expect(find.byType(CameraHudScreen), findsOneWidget);
    expect(find.text('Kayıt sürerken çıkılamaz — önce testi bitirin'), findsOneWidget);
    await unmount(t);
  });
}
