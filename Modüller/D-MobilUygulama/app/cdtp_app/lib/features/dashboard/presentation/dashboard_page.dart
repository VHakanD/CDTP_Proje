import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/key_value_table.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../core/widgets/tilt_indicator.dart';
import '../../connection/application/robot_connection_controller.dart';
import '../../connection/domain/connection_state.dart';
import '../../connection/domain/robot_telemetry.dart';

/// Ana panel: robottan gelen canli telemetri (sartname Modul D: sarj + egim, 1 Hz).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key, this.onOpenConnection});

  final VoidCallback? onOpenConnection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(robotConnectionProvider);
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final t = conn.latest;
    final theme = Theme.of(context);

    final tiltHistory = conn.history.map((e) => e.tiltDeg).whereType<double>().toList();
    final batteryHistory = conn.history.map((e) => e.batteryPct).whereType<double>().toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (conn.phase == LinkPhase.disconnected)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(child: Text('Robota bağlı değil')),
                    FilledButton(
                      onPressed: () => ref.read(robotConnectionProvider.notifier).connect(),
                      child: const Text('Bağlan'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onOpenConnection,
                      child: const Text('Ayarlar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SectionCard(
          title: 'Robot durumu',
          trailing: t == null
              ? null
              : Text(
                  'Son veri ${Fmt.seconds(now.difference(t.receivedAt).inMilliseconds / 1000)} önce',
                  style: theme.textTheme.bodySmall,
                ),
          child: MetricGrid(children: [
            MetricTile(
              label: 'Şarj',
              value: Fmt.percent(t?.batteryPct),
              caption: t?.batteryV == null ? null : Fmt.number(t!.batteryV, digits: 2, suffix: ' V'),
              available: t?.batteryPct != null,
              valueColor: (t?.batteryPct ?? 100) < 20 ? AppColors.fail : null,
            ),
            MetricTile(
              label: 'Eğim',
              value: Fmt.degrees(t?.tiltDeg),
              available: t?.tiltDeg != null,
              valueColor: (t?.tiltDeg?.abs() ?? 0) >= 10 ? AppColors.fail : null,
            ),
            MetricTile(
              label: 'Şarj durumu',
              value: t?.charging == null ? Fmt.empty : (t!.charging! ? 'Şarj oluyor' : 'Şarj olmuyor'),
              available: t?.charging != null,
              valueColor: t?.charging == true ? AppColors.pass : null,
            ),
            MetricTile(
              label: 'İstasyon',
              value: Fmt.boolTr(t?.docked, yes: 'Yerleşti', no: 'Dışarıda'),
              available: t?.docked != null,
            ),
            MetricTile(
              label: 'Robot durumu',
              value: t?.state?.label ?? Fmt.empty,
              available: t?.state != null,
              valueColor: t?.state == RobotReportedState.fallen ? AppColors.fail : null,
            ),
            MetricTile(
              label: 'İlaç kutusu',
              value: Fmt.boolTr(t?.boxPresent, yes: 'Yerinde', no: 'Yok'),
              available: t?.boxPresent != null,
              valueColor: t?.boxPresent == false ? AppColors.fail : null,
            ),
            MetricTile(
              label: 'IR istasyon',
              value: Fmt.boolTr(t?.irDetected, yes: 'Algılandı', no: 'Yok'),
              available: t?.irDetected != null,
            ),
            MetricTile(
              label: 'Son eldiven komutu',
              value: t?.lastCommand?.label ?? Fmt.empty,
              caption: t?.lastCommandSeq == null ? null : '#${t!.lastCommandSeq}',
              available: t?.lastCommand != null,
            ),
          ]),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final tiltCard = SectionCard(
              title: 'Eğim',
              child: Row(
                children: [
                  TiltIndicator(tiltDeg: t?.tiltDeg, size: 120),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Sparkline(
                      values: tiltHistory,
                      color: theme.colorScheme.secondary,
                      minY: -20,
                      maxY: 20,
                      height: 120,
                      referenceLines: const [-10, 0, 10],
                    ),
                  ),
                ],
              ),
            );
            final batteryCard = SectionCard(
              title: 'Pil geçmişi (son 2 dk)',
              child: Sparkline(
                values: batteryHistory,
                color: theme.colorScheme.primary,
                minY: 0,
                maxY: 100,
                height: 120,
                referenceLines: const [20, 50, 80],
              ),
            );
            if (c.maxWidth < 760) {
              return Column(children: [tiltCard, const SizedBox(height: 12), batteryCard]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tiltCard),
                const SizedBox(width: 12),
                Expanded(child: batteryCard),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Ham telemetri',
          child: KeyValueTable(rows: [
            ('Sıra no (seq)', t?.seq?.toString() ?? Fmt.empty),
            ('Robot çalışma süresi', t?.uptimeMs == null ? Fmt.empty : Fmt.clock(Duration(milliseconds: t!.uptimeMs!))),
            ('Alınma zamanı', t == null ? Fmt.empty : Fmt.time(t.receivedAt)),
            ('Telemetri frekansı',
                conn.stats.measuredHz == null ? Fmt.empty : '${Fmt.number(conn.stats.measuredHz, digits: 2)} Hz'),
            ('En uzun boşluk', Fmt.seconds(conn.stats.maxGapMs / 1000)),
          ]),
        ),
      ],
    );
  }
}
