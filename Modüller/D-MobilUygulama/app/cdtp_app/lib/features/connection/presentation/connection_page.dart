import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/key_value_table.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../application/robot_connection_controller.dart';
import '../domain/connection_state.dart';
import 'connection_badge.dart';

/// Robot baglanti modulu: yol secimi, adres, baglan/kes, kalite ve olay gunlugu.
class ConnectionPage extends ConsumerStatefulWidget {
  const ConnectionPage({super.key});

  @override
  ConsumerState<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends ConsumerState<ConnectionPage> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _path;
  late final TextEditingController _bleName;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _host = TextEditingController(text: s.wsHost);
    _port = TextEditingController(text: s.wsPort.toString());
    _path = TextEditingController(text: s.wsPath);
    _bleName = TextEditingController(text: s.bleNamePrefix);
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _path.dispose();
    _bleName.dispose();
    super.dispose();
  }

  /// Hazir adres: alanlari doldurur.
  void _applyPreset(String host, int port, String path) {
    setState(() {
      _host.text = host;
      _port.text = port.toString();
      _path.text = path;
    });
  }

  Future<void> _saveAndConnect() async {
    final port = int.tryParse(_port.text.trim());
    if (port == null || port <= 0 || port > 65535) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Port 1–65535 arasında olmalı')));
      return;
    }
    var path = _path.text.trim();
    if (!path.startsWith('/')) path = '/$path';
    await ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(
            wsHost: _host.text.trim(),
            wsPort: port,
            wsPath: path,
            bleNamePrefix: _bleName.text.trim(),
          ),
        );
    await ref.read(robotConnectionProvider.notifier).connect();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final conn = ref.watch(robotConnectionProvider);
    final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
    final busy = conn.phase != LinkPhase.disconnected;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Bağlantı yolu',
          trailing: StatusChip(label: conn.phase.label, color: linkPhaseColor(conn.phase)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TransportKind>(
                segments: [
                  for (final t in TransportKind.values)
                    ButtonSegment(value: t, label: Text(t.label)),
                ],
                selected: {settings.transport},
                onSelectionChanged: busy
                    ? null
                    : (v) => ref
                        .read(settingsProvider.notifier)
                        .update((s) => s.copyWith(transport: v.first)),
              ),
              const SizedBox(height: 16),
              if (settings.transport == TransportKind.wifi) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _host,
                        enabled: !busy,
                        decoration: const InputDecoration(labelText: 'Adres (IP)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _port,
                        enabled: !busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Port'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _path,
                        enabled: !busy,
                        decoration: const InputDecoration(labelText: 'Yol'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('ESP32 SoftAP 192.168.4.1:80/ws'),
                      onPressed: busy ? null : () => _applyPreset('192.168.4.1', 80, '/ws'),
                    ),
                    ActionChip(
                      label: const Text('Simülatör localhost:8765/ws'),
                      onPressed: busy ? null : () => _applyPreset('localhost', 8765, '/ws'),
                    ),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: _bleName,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'BLE cihaz adı (başlangıcı)'),
                ),
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Web tarayıcıda BLE desteklenmez.',
                      style: TextStyle(color: AppColors.fail.withValues(alpha: 0.9)),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : _saveAndConnect,
                      icon: const Icon(Icons.link),
                      label: const Text('Bağlan'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy
                          ? () => ref.read(robotConnectionProvider.notifier).disconnect()
                          : null,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Bağlantıyı kes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Durum ve kalite',
          child: KeyValueTable(rows: [
            ('Hedef', conn.endpoint),
            ('Robot', conn.info?.device ?? Fmt.empty),
            ('Yazılım / protokol',
                conn.info == null ? Fmt.empty : '${conn.info!.firmware} / v${conn.info!.protocol}'),
            ('Bağlanma zamanı',
                conn.stats.connectedAt == null ? Fmt.empty : Fmt.time(conn.stats.connectedAt!)),
            ('Son veri',
                conn.stats.lastRxAt == null
                    ? Fmt.empty
                    : '${Fmt.seconds(now.difference(conn.stats.lastRxAt!).inMilliseconds / 1000)} önce'),
            ('Telemetri frekansı',
                conn.stats.measuredHz == null ? Fmt.empty : '${Fmt.number(conn.stats.measuredHz, digits: 2)} Hz (hedef 1 Hz)'),
            ('En uzun boşluk', '${Fmt.seconds(conn.stats.maxGapMs / 1000)} (sınır 2 s)'),
            ('2 s aşımı', conn.stats.gapViolations.toString()),
            ('Gidiş-dönüş (RTT)', conn.stats.rttMs == null ? Fmt.empty : '${conn.stats.rttMs} ms'),
            ('Telemetri paketi', conn.stats.telemetryCount.toString()),
            ('Çözülemeyen mesaj', conn.stats.parseErrors.toString()),
            ('Yeniden bağlanma', conn.stats.reconnects.toString()),
            ('Son hata', conn.lastError ?? Fmt.empty),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Olay günlüğü',
          child: conn.events.isEmpty
              ? Text(Fmt.empty, style: Theme.of(context).textTheme.bodyMedium)
              : Column(
                  children: [
                    for (final e in conn.events)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 72,
                              child: Text(
                                Fmt.time(e.time),
                                style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.message,
                                style: TextStyle(
                                  color: switch (e.level) {
                                    LinkEventLevel.info => null,
                                    LinkEventLevel.warning => AppColors.warning,
                                    LinkEventLevel.error => AppColors.fail,
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        const SectionCard(
          title: 'Robota bağlanma',
          child: KeyValueTable(keyFlex: 1, valueFlex: 9, rows: [
            ('1', 'Robotu açın. ESP32 "CDTP-ROBOT" adlı Wi-Fi ağını yayınlar.'),
            ('2', 'Telefonu bu ağa bağlayın. "İnternet yok" uyarısında bağlı kalın; mobil veriyi kapatın.'),
            ('3', 'Bu sayfada "ESP32 SoftAP" hazır ayarını seçip Bağlan\'a basın.'),
            ('4', 'Durum "Bağlı" ve frekans ≈ 1 Hz olmalı. Ayrıntı: docs/PROTOCOL.md'),
          ]),
        ),
      ],
    );
  }
}
