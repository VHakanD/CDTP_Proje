import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../camera/application/camera_session_controller.dart';
import '../../camera/presentation/camera_preview_panel.dart';
import '../../connection/application/robot_connection_controller.dart';
import '../../connection/domain/connection_state.dart';
import '../../connection/presentation/connection_badge.dart';
import '../../reports/presentation/report_detail_page.dart';
import '../application/test_session_controller.dart';
import '../domain/test_task.dart';
import 'verdict_style.dart';

/// Canli test ekrani: kamera + canli olcumler + Testi Baslat / Testi Bitir.
class LiveTestPage extends ConsumerStatefulWidget {
  const LiveTestPage({super.key, required this.task, required this.params});

  final TestTask task;
  final TaskParams params;

  @override
  ConsumerState<LiveTestPage> createState() => _LiveTestPageState();
}

class _LiveTestPageState extends ConsumerState<LiveTestPage> {
  late final CameraSessionController _camera;

  @override
  void initState() {
    super.initState();
    _camera = ref.read(cameraSessionProvider.notifier);
    // Build sirasinda provider degistirmemek icin bir sonraki tura birakilir.
    Future.microtask(() {
      ref.read(testSessionProvider.notifier).select(widget.task, widget.params);
      _camera.initialize();
    });
  }

  @override
  void dispose() {
    // Sayfadan cikinca kamera kapatilir (pil ve isinma).
    unawaited(Future.microtask(_camera.release));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(testSessionProvider);
    final conn = ref.watch(robotConnectionProvider);

    // Test kaydedilince rapor sayfasina gecilir.
    ref.listen(testSessionProvider, (prev, next) {
      if (prev?.phase != SessionPhase.finished &&
          next.phase == SessionPhase.finished &&
          next.report != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => ReportDetailPage(report: next.report!)),
        );
      }
    });

    final locked = session.phase == SessionPhase.running || session.phase == SessionPhase.saving;

    return PopScope(
      canPop: !locked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.task.title),
          actions: const [
            Padding(padding: EdgeInsets.only(right: 12), child: Center(child: ConnectionBadge())),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final camera = CameraPreviewPanel(
                overlay: StatusChip(
                  label: Fmt.clockPrecise(session.elapsed),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              );
              final panel = _LivePanel(task: widget.task, params: widget.params);
              final controls = _Controls(connected: conn.phase == LinkPhase.connected);

              if (c.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ListView(padding: const EdgeInsets.all(16), children: [camera]),
                    ),
                    Expanded(
                      flex: 4,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                        children: [panel, const SizedBox(height: 12), controls],
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [camera, const SizedBox(height: 12), controls, const SizedBox(height: 12), panel],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Canli olcum kutulari (sartname 5.2: sarj, egim, sure, hareket, yon).
class _LivePanel extends ConsumerWidget {
  const _LivePanel({required this.task, required this.params});

  final TestTask task;
  final TaskParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(testSessionProvider);
    final t = ref.watch(robotConnectionProvider).latest;
    final tracker = ref.watch(motionTrackerProvider);
    final m = session.lastMotion;
    final cam = tracker.isImplemented;

    return SectionCard(
      title: 'Canlı ölçüm',
      trailing: StatusChip(
        label: session.phase.label,
        color: session.phase == SessionPhase.running ? AppColors.fail : AppColors.missing,
        dense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ModuleBadge(task.module, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  params.expectedDirection == null
                      ? task.criterion
                      : '${task.criterion}  ·  Beklenen yön: ${params.expectedDirection!.label}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MetricGrid(minTileWidth: 140, children: [
            MetricTile(label: 'Süre', value: Fmt.clockPrecise(session.elapsed)),
            MetricTile(label: 'Şarj', value: Fmt.percent(t?.batteryPct), available: t?.batteryPct != null),
            MetricTile(label: 'Eğim', value: Fmt.degrees(t?.tiltDeg), available: t?.tiltDeg != null),
            MetricTile(
              label: 'Şarj durumu',
              value: t?.charging == null ? Fmt.empty : (t!.charging! ? 'Şarj oluyor' : 'Yok'),
              available: t?.charging != null,
              valueColor: t?.charging == true ? AppColors.pass : null,
            ),
            MetricTile(
              label: 'Hareket (kamera)',
              value: m?.state.label ?? Fmt.empty,
              available: cam && m != null,
            ),
            MetricTile(
              label: 'Yön (kamera)',
              value: m?.direction.label ?? Fmt.empty,
              available: cam && m != null,
            ),
            MetricTile(
              label: 'Konum (kamera)',
              value: m?.hasPosition == true
                  ? '${Fmt.number(m!.xM, digits: 2)}; ${Fmt.number(m.yM, digits: 2)}'
                  : Fmt.empty,
              caption: 'x; y (m)',
              available: cam && m?.hasPosition == true,
            ),
            MetricTile(
              label: 'Robot durumu',
              value: t?.state?.label ?? Fmt.empty,
              available: t?.state != null,
            ),
            MetricTile(
              label: 'Telemetri',
              value: session.telemetryCount.toString(),
              caption: 'paket (bu test)',
            ),
          ]),
          if (!cam) ...[
            const SizedBox(height: 8),
            Text(
              'Kamera hareket tespiti yapılandırılmadı; kamera kriterleri "Veri yok" olarak raporlanır.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Testi Baslat / Testi Bitir dugmeleri.
class _Controls extends ConsumerWidget {
  const _Controls({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(testSessionProvider);
    final ctrl = ref.read(testSessionProvider.notifier);

    switch (session.phase) {
      case SessionPhase.setup:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: connected ? ctrl.start : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Testi Başlat'),
            ),
            if (!connected)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Robot bağlı değil',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      case SessionPhase.running:
        return FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.fail),
          onPressed: () => ctrl.stop(),
          icon: const Icon(Icons.stop),
          label: const Text('Testi Bitir'),
        );
      case SessionPhase.saving:
        return const Center(
          child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
        );
      case SessionPhase.finished:
        // Buraya sadece kayit hatasi olursa gelinir (basarida rapor sayfasina gecilir).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(session.error ?? 'Test bitti', style: const TextStyle(color: AppColors.fail)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: ctrl.reset, child: const Text('Yeni test')),
          ],
        );
    }
  }
}
