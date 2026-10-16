import 'dart:async';

import 'package:cdtp_monitor/app.dart';
import 'package:cdtp_monitor/app_scope.dart';
import 'package:cdtp_monitor/data/repositories/report_repository.dart';
import 'package:cdtp_monitor/data/repositories/robot_repository.dart';
import 'package:cdtp_monitor/data/repositories/tracking_repository.dart';
import 'package:cdtp_monitor/data/services/report_file_service.dart';
import 'package:cdtp_monitor/data/services/robot_socket_service.dart';
import 'package:cdtp_monitor/data/services/tracker/motion_tracker.dart';
import 'package:cdtp_monitor/domain/models/motion.dart';
import 'package:cdtp_monitor/domain/models/test_task.dart';
import 'package:cdtp_monitor/router.dart';
import 'package:cdtp_monitor/ui/core/session_store.dart';
import 'package:cdtp_monitor/ui/core/widgets/direction_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTracker implements MotionTracker {
  final ctrl = StreamController<TrackSample>.broadcast();
  @override
  String get name => 'sahte';
  @override
  double get sensorAspect => 1;
  @override
  Stream<TrackSample> get samples => ctrl.stream;
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

class Harness {
  Harness() {
    robot = RobotRepository(RobotSocketService());
    tracker = FakeTracker();
    session = SessionStore();
  }
  late final RobotRepository robot;
  late final FakeTracker tracker;
  late final SessionStore session;

  Widget app(String initial) => AppScope(
        robot: robot,
        reports: ReportRepository(MemoryReportFileService()),
        session: session,
        tracking: TrackingRepository(robot, trackerFactory: () => tracker),
        child: CdtpMonitorApp(router: buildRouter(initial: initial)),
      );
}

Future<void> phone(WidgetTester t) async {
  t.view.physicalSize = const Size(400, 860);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// Periyodik zamanlayıcıları kapatmak için ekranı boşalt.
Future<void> unmount(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('dashboard_disables_task_button_when_lost', (t) async {
    await phone(t);
    await t.pumpWidget(Harness().app('/dashboard'));
    await t.pump();
    final btn = t.widget<FilledButton>(find.byKey(const Key('choose-task')));
    expect(btn.onPressed, isNull);
    expect(find.textContaining('2 s\'den uzun'), findsOneWidget);
  });

  testWidgets('guidance_requires_expected_direction', (t) async {
    await phone(t);
    final h = Harness();
    await t.pumpWidget(h.app('/tasks'));
    await t.pump();
    await t.tap(find.byKey(const Key('task-guidance')));
    await t.pump();
    expect(t.widget<FilledButton>(find.byKey(const Key('to-scene'))).onPressed, isNull);
    await t.tap(find.byKey(const Key('dir-forward')));
    await t.pump();
    expect(h.session.expected, Heading.forward);
    expect(t.widget<FilledButton>(find.byKey(const Key('to-scene'))).onPressed, isNotNull);
  });

  group('05 Kamera + HUD', () {
    Future<Harness> openHud(WidgetTester t) async {
      await phone(t);
      final h = Harness()..session.selectTask(TaskKind.staticBalance);
      await t.pumpWidget(h.app('/camera'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      return h;
    }

    testWidgets('default_ratio_is_square', (t) async {
      await openHud(t);
      final r = t.getRect(find.byKey(const Key('camera-surface')));
      expect(r.width, closeTo(r.height, 0.5));
      await unmount(t);
    });

    testWidgets('ratio_tall_overlays_strip', (t) async {
      await openHud(t);
      expect(find.byKey(const Key('info-strip')), findsOneWidget);
      await t.tap(find.text('9:16'));
      await t.pump();
      expect(find.byKey(const Key('info-strip-overlay')), findsOneWidget);
      expect(find.byKey(const Key('info-strip')), findsNothing);
      await unmount(t);
    });

    testWidgets('direction_indicator_on_left_edge', (t) async {
      await openHud(t);
      final cam = t.getRect(find.byKey(const Key('camera-surface')));
      final dir = t.getRect(find.byKey(const Key('direction-indicator')));
      expect(dir.left - cam.left, lessThanOrEqualTo(12));
      expect(dir.width, lessThanOrEqualTo(72));
      expect(dir.width, DirectionIndicator.width);
      expect((dir.center.dy - cam.center.dy).abs(), lessThan(8)); // dikey ortalı
      await unmount(t);
    });

    testWidgets('lost_shows_banner_then_visible_hides_it', (t) async {
      final h = await openHud(t);
      expect(find.byKey(const Key('lost-banner')), findsOneWidget);
      h.tracker.ctrl.add(TrackSample(t: h.robot.now(), center: const Offset(0.5, 0.7), confidence: 0.95));
      await t.pump(); // örnek işlenir
      await t.pump(); // yeni kare çizilir
      expect(find.byKey(const Key('lost-banner')), findsNothing);
      expect(find.textContaining('Robot görünüyor'), findsOneWidget);
      await unmount(t);
    });
  });
}
