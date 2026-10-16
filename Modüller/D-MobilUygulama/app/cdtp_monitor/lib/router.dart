import 'package:go_router/go_router.dart';

import 'ui/features/camera_hud/views/camera_hud_screen.dart';
import 'ui/features/connection/views/connection_screen.dart';
import 'ui/features/dashboard/views/dashboard_screen.dart';
import 'ui/features/reports/views/report_detail_screen.dart';
import 'ui/features/reports/views/reports_screen.dart';
import 'ui/features/result/views/result_screen.dart';
import 'ui/features/scene/views/scene_screen.dart';
import 'ui/features/tasks/views/task_select_screen.dart';

/// Wireframe akışı: 01 → 02 → 03 → 04 → 05 → 06 → 07.
GoRouter buildRouter({String initial = '/connect'}) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/connect', builder: (_, _) => const ConnectionScreen()),
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
        GoRoute(path: '/tasks', builder: (_, _) => const TaskSelectScreen()),
        GoRoute(path: '/scene', builder: (_, _) => const SceneScreen()),
        GoRoute(path: '/camera', builder: (_, _) => const CameraHudScreen()),
        GoRoute(
          path: '/result/:id',
          builder: (_, s) => ResultScreen(reportId: s.pathParameters['id']!),
        ),
        GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
        GoRoute(
          path: '/reports/:id',
          builder: (_, s) => ReportDetailScreen(reportId: s.pathParameters['id']!),
        ),
      ],
    );
