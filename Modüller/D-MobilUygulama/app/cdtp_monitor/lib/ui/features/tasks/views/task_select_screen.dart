import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_scope.dart';
import '../../../../domain/models/motion.dart';
import '../../../../domain/models/test_task.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/link_badge.dart';
import '../../../core/widgets/wf_parts.dart';

/// 03 · Görev seçimi. Görev B için beklenen yön de seçilir.
class TaskSelectScreen extends StatelessWidget {
  const TaskSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final s = scope.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Görev seçimi')),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => WfPage(
          bottom: FilledButton(
            key: const Key('to-scene'),
            onPressed: s.taskReady ? () => context.push('/scene') : null,
            child: const Text('Sahne hazırlamaya geç'),
          ),
          children: [
            ValueListenableBuilder(valueListenable: scope.robot.link, builder: (_, l, _) => LinkBadge(l)),
            const SectionLabel('Bir görev seçin'),
            for (final k in TaskKind.values) ...[
              _TaskCard(
                task: k,
                selected: s.task == k,
                expected: s.expected,
                onTap: () => s.selectTask(k),
                onExpected: s.selectExpected,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.selected,
    required this.expected,
    required this.onTap,
    required this.onExpected,
  });

  final TaskKind task;
  final bool selected;
  final Heading? expected;
  final VoidCallback onTap;
  final ValueChanged<Heading> onExpected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.hair : AppColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        key: Key('task-${task.name}'),
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(task.label, style: const TextStyle(fontWeight: FontWeight.w700))),
              Pill('Modül ${task.module}'),
            ]),
            const SizedBox(height: 4),
            Text('Başarı: ${task.goal}', style: const TextStyle(fontSize: 12)),
            Text('Bitiş: ${task.endRule}', style: const TextStyle(fontSize: 12, color: AppColors.mid)),
            if (task == TaskKind.guidance && selected) ...[
              const SizedBox(height: 8),
              const Text('Beklenen yön', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: [
                for (final h in Heading.choices)
                  ChoiceChip(
                    key: Key('dir-${h.name}'),
                    label: Text(h.label),
                    selected: expected == h,
                    onSelected: (_) => onExpected(h),
                  ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}
