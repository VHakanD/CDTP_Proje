import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/key_value_table.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../camera/application/camera_session_controller.dart';
import '../../reports/application/report_providers.dart';
import '../application/settings_controller.dart';
import '../domain/app_settings.dart';

/// Ayarlar modulu.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final tracker = ref.watch(motionTrackerProvider);
    final chain = ref.watch(chainVerificationProvider);
    final persistent = ref.watch(reportRepositoryProvider).isPersistent;
    final th = s.thresholds;

    // Esik satiri: dokununca sayi girme penceresi acilir.
    Widget thresholdTile(
      String label,
      double value,
      String unit,
      EvaluationThresholds Function(double v) apply,
    ) =>
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label),
          trailing: Text(
            '${Fmt.number(value, digits: value % 1 == 0 ? 0 : 2)} $unit',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          onTap: () async {
            final v = await _askNumber(context, label, value);
            if (v != null) await ctrl.updateThresholds((_) => apply(v));
          },
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Görünüm',
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
              ButtonSegment(value: ThemeMode.light, label: Text('Açık')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Koyu')),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => ctrl.update((x) => x.copyWith(themeMode: v.first)),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Kamera',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Test sırasında video kaydı'),
                value: s.recordVideo,
                onChanged: (v) => ctrl.update((x) => x.copyWith(recordVideo: v)),
              ),
              KeyValueTable(rows: [
                ('Hareket tespit yöntemi', tracker.name),
                // TODO(kamera): kalibrasyon sayfasi tespit yontemi secilince eklenecek.
                ('Kalibrasyon', 'Yapılmadı'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Değerlendirme eşikleri',
          trailing: TextButton(onPressed: ctrl.resetThresholds, child: const Text('Varsayılan')),
          child: Column(
            children: [
              thresholdTile('Statik denge süresi', th.staticBalanceSeconds, 's',
                  (v) => th.copyWith(staticBalanceSeconds: v)),
              thresholdTile('Süre toleransı', th.timeToleranceSeconds, 's',
                  (v) => th.copyWith(timeToleranceSeconds: v)),
              thresholdTile('Mesafe alt sınırı', th.distanceMinM, 'm',
                  (v) => th.copyWith(distanceMinM: v)),
              thresholdTile('Mesafe üst sınırı', th.distanceMaxM, 'm',
                  (v) => th.copyWith(distanceMaxM: v)),
              thresholdTile('Dönüş açısı', th.turnTargetDeg, '°', (v) => th.copyWith(turnTargetDeg: v)),
              thresholdTile('Dönüş toleransı', th.turnToleranceDeg, '°',
                  (v) => th.copyWith(turnToleranceDeg: v)),
              thresholdTile('Şarj başlama penceresi', th.chargeStartWindowSeconds, 's',
                  (v) => th.copyWith(chargeStartWindowSeconds: v)),
              thresholdTile('Başlangıç denge süresi', th.initialBalanceSeconds, 's',
                  (v) => th.copyWith(initialBalanceSeconds: v)),
              thresholdTile('Hedefte bekleme', th.targetWaitSeconds, 's',
                  (v) => th.copyWith(targetWaitSeconds: v)),
              thresholdTile('Düşme eğimi', th.fallTiltDeg, '°', (v) => th.copyWith(fallTiltDeg: v)),
              thresholdTile('Statik yer değiştirme', th.staticMaxDisplacementM, 'm',
                  (v) => th.copyWith(staticMaxDisplacementM: v)),
              thresholdTile('En uzun bağlantı boşluğu', th.maxLinkGapSeconds, 's',
                  (v) => th.copyWith(maxLinkGapSeconds: v)),
              thresholdTile('Yönlendirme zaman aşımı', th.guidanceTimeoutSeconds, 's',
                  (v) => th.copyWith(guidanceTimeoutSeconds: v)),
              thresholdTile('Şarj zaman aşımı', th.chargingTimeoutSeconds, 's',
                  (v) => th.copyWith(chargingTimeoutSeconds: v)),
              thresholdTile('Bütünleşik görev zaman aşımı', th.integratedTimeoutSeconds, 's',
                  (v) => th.copyWith(integratedTimeoutSeconds: v)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Veri',
          trailing: TextButton(
            onPressed: () => ref.invalidate(chainVerificationProvider),
            child: const Text('Doğrula'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueTable(rows: [
                ('Depolama', persistent ? 'SQLite (kalıcı)' : 'Bellek (web önizleme)'),
                ('Kayıt koruması', 'Ekleme yalnız; güncelleme/silme engelli'),
                ('Hash zinciri', chain.when(
                  data: (v) => v.ok
                      ? '${v.checked} kayıt doğrulandı'
                      : '#${v.brokenAtSeq} bozuk: ${v.reason}',
                  loading: () => 'Doğrulanıyor',
                  error: (e, _) => 'Hata: $e',
                )),
              ]),
              const SizedBox(height: 8),
              chain.maybeWhen(
                data: (v) => StatusChip(
                  label: v.ok ? 'Bütünlük sağlam' : 'Bütünlük bozuk',
                  color: v.ok ? AppColors.pass : AppColors.fail,
                  dense: true,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Hakkında',
          child: KeyValueTable(rows: [
            ('Uygulama', AppConstants.appName),
            ('Sürüm', AppConstants.appVersion),
            ('Robot protokolü', 'v${AppConstants.protocolVersion} (JSON, 1 Hz)'),
            ('Platform', kIsWeb ? 'Web' : defaultTargetPlatform.name),
          ]),
        ),
      ],
    );
  }

  static Future<double?> _askNumber(BuildContext context, String label, double current) {
    final controller = TextEditingController(text: current.toString());
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.replaceAll(',', '.').trim());
              Navigator.pop(ctx, (v != null && v >= 0) ? v : null);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
