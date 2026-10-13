import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../camera/application/camera_session_controller.dart';
import '../../camera/domain/motion_sample.dart';
import '../../connection/application/robot_connection_controller.dart';
import '../../connection/domain/connection_state.dart';
import '../domain/test_task.dart';
import 'live_test_page.dart';
import 'verdict_style.dart';

/// Test modulu giris sayfasi: dort olcum gorevinden biri secilir.
class TaskSelectPage extends ConsumerStatefulWidget {
  const TaskSelectPage({super.key});

  @override
  ConsumerState<TaskSelectPage> createState() => _TaskSelectPageState();
}

class _TaskSelectPageState extends ConsumerState<TaskSelectPage> {
  /// Yonlendirme gorevi icin beklenen yon.
  MotionDirection _direction = MotionDirection.forward;

  void _open(TestTask task) {
    final params = task == TestTask.guidance
        ? TaskParams(expectedDirection: _direction)
        : const TaskParams();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LiveTestPage(task: task, params: params)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(robotConnectionProvider);
    final tracker = ref.watch(motionTrackerProvider);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ön koşullar', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text('Robot bağlantısı: ${conn.phase.label}', style: muted),
                      Text('Kamera hareket tespiti: ${tracker.name}', style: muted),
                      Text('Telefon sabit, robot dengede ve hareketsiz konumda olmalı.', style: muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final task in TestTask.values) ...[
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(task),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        ModuleBadge(task.module),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.title, style: theme.textTheme.titleMedium),
                              Text('${task.criterion}  ·  ${task.rubric}', style: muted),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                    if (task == TestTask.guidance) ...[
                      const SizedBox(height: 12),
                      SegmentedButton<MotionDirection>(
                        showSelectedIcon: false,
                        segments: [
                          for (final d in const [
                            MotionDirection.forward,
                            MotionDirection.backward,
                            MotionDirection.left,
                            MotionDirection.right,
                          ])
                            ButtonSegment(value: d, label: Text(d.label)),
                        ],
                        selected: {_direction},
                        onSelectionChanged: (v) => setState(() => _direction = v.first),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (conn.phase != LinkPhase.connected)
          Text(
            'Testi başlatmak için robot bağlantısı gerekir.',
            style: muted,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
