import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_scope.dart';
import '../../../../domain/models/link_health.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/gauges.dart';
import '../../../core/widgets/link_badge.dart';
import '../../../core/widgets/wf_parts.dart';

/// 02 · Ana panel / canlı sensör. Veriler 1 Hz telemetriden gelir; ekran
/// bağlantı sağlığıyla (250 ms) yenilenir.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// "Bağlantıyı kes" düğmesi ve onaylanan geri tuşu: kamerayı da bırakır.
  static Future<void> _disconnect(BuildContext context, AppScope scope) async {
    await scope.robot.disconnect();
    await scope.tracking.close();
    if (context.mounted) context.go('/connect');
  }

  /// Panel akışın köküdür; sistem geri tuşu uygulamayı kapatmak yerine sorar.
  static Future<void> _confirmBack(BuildContext context, AppScope scope) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Bağlantı kesilsin mi?'),
        content: const Text('Robot bağlantısı kapanır ve bağlantı ekranına dönülür.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Kes')),
        ],
      ),
    );
    if (ok == true && context.mounted) await _disconnect(context, scope);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final robot = scope.robot;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmBack(context, scope);
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Ana panel'),
        actions: [
          IconButton(
            tooltip: 'Rapor geçmişi',
            onPressed: () => context.push('/reports'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: ValueListenableBuilder<LinkState>(
        valueListenable: robot.link,
        builder: (context, l, _) {
          final t = robot.latest.value;
          final lost = l.level == LinkLevel.lost || l.level == LinkLevel.disconnected;
          final since = l.sinceLastTelemetry ?? Duration.zero;
          return WfPage(
            bottom: Column(mainAxisSize: MainAxisSize.min, children: [
              FilledButton(
                key: const Key('choose-task'),
                onPressed: lost || t == null ? null : () => context.push('/tasks'),
                child: const Text('Görev seç'),
              ),
              TextButton(
                onPressed: () => _disconnect(context, scope),
                child: const Text('Bağlantıyı kes'),
              ),
            ]),
            children: [
              Row(children: [
                Expanded(child: LinkBadge(l)),
                Text(l.device ?? '', style: const TextStyle(fontSize: 12, color: AppColors.mid)),
              ]),
              if (lost) ...[
                const SizedBox(height: 8),
                const WfBox(
                  dashed: true,
                  child: Text('Bağlantı 2 s\'den uzun süredir yok. Değerler son alınan paketten; '
                      'yeniden bağlanılıyor…', style: TextStyle(fontSize: 12)),
                ),
              ],
              const SectionLabel('Şarj ve pil'),
              WfBox(
                child: Column(children: [
                  KvRow('Pil', t == null ? '—' : '%${fmtNum(t.batteryPct, 0)}', bold: true),
                  const SizedBox(height: 4),
                  Meter((t?.batteryPct ?? 0) / 100),
                  const SizedBox(height: 4),
                  KvRow('Şarj', t == null ? '—' : (t.charging ? 'ŞARJ OLUYOR' : 'şarj olmuyor')),
                ]),
              ),
              const SectionLabel('Eğim açısı'),
              WfBox(
                child: Column(children: [
                  KvRow('Anlık', t == null ? '—' : '${fmtSigned(t.tiltDeg)}°', bold: true),
                  const SizedBox(height: 6),
                  TiltGauge(t?.tiltDeg),
                ]),
              ),
              const SectionLabel('Eğim, son 60 s'),
              WfBox(child: Sparkline([for (final x in robot.history(const Duration(seconds: 60))) x.tiltDeg])),
              const SectionLabel('Bağlantı sağlığı'),
              WfBox(
                child: Column(children: [
                  KvRow('Son paket', l.telemetryReceived ? '${fmtSecs(since)} önce' : '—'),
                  KvRow('Paket hızı', '${fmtNum(l.hz)} Hz'),
                  const SizedBox(height: 6),
                  Meter(since.inMilliseconds / 2000,
                      color: since > LinkHealth.okLimit ? AppColors.warn : AppColors.line),
                  const SizedBox(height: 2),
                  const Row(children: [
                    Text('0 s', style: TextStyle(fontSize: 11, color: AppColors.mid)),
                    Spacer(),
                    Text('kopma sınırı 2 s', style: TextStyle(fontSize: 11, color: AppColors.mid)),
                  ]),
                ]),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
