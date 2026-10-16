import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_scope.dart';
import '../../../../domain/models/link_health.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/link_badge.dart';
import '../../../core/widgets/wf_parts.dart';
import '../view_models/connection_view_model.dart';

/// 01 · Bağlantı
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  ConnectionViewModel? _vm;
  late final TextEditingController addr;

  ConnectionViewModel get vm => _vm!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    _vm = ConnectionViewModel(AppScope.of(context).robot);
    addr = TextEditingController(text: vm.address);
  }

  @override
  void dispose() {
    vm.dispose();
    addr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Robot bağlantısı')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final l = vm.link;
          return WfPage(
            bottom: Column(mainAxisSize: MainAxisSize.min, children: [
              FilledButton(
                onPressed: vm.busy
                    ? null
                    : vm.verified
                        ? () => context.go('/dashboard')
                        : vm.connect,
                child: Text(vm.verified
                    ? 'Ana panele geç'
                    : vm.busy
                        ? 'Bağlanıyor…'
                        : l.error != null
                            ? 'Yeniden dene'
                            : 'Bağlan'),
              ),
              TextButton(onPressed: () => context.go('/reports'), child: const Text('Rapor geçmişi')),
            ]),
            children: [
              WfBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  LinkBadge(l),
                  if (l.device != null)
                    Text('Cihaz: ${l.device}', style: const TextStyle(fontSize: 12, color: AppColors.mid)),
                ]),
              ),
              const SectionLabel('Bilinen robotlar'),
              WfBox(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (final p in ConnectionViewModel.presets)
                    ListTile(
                      dense: true,
                      leading: Icon(vm.address == p.address ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18),
                      title: Text(p.name),
                      subtitle: Text('${p.address}\n${p.note}', style: const TextStyle(fontSize: 11)),
                      isThreeLine: true,
                      onTap: () {
                        addr.text = p.address;
                        vm.choose(p.address);
                      },
                    ),
                ]),
              ),
              const SectionLabel('Ya da adresi elle gir'),
              TextField(
                controller: addr,
                keyboardType: TextInputType.url,
                autocorrect: false,
                onChanged: vm.choose,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  errorText: vm.inputError,
                  hintText: 'ws://192.168.4.1:80/ws',
                ),
              ),
              if (l.error != null) ...[
                const SizedBox(height: 10),
                WfBox(dashed: true, child: Text(l.error!, style: const TextStyle(fontSize: 12))),
              ],
              const SectionLabel('Bağlantı doğrulama'),
              WfBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CheckLine('Robot bulundu', done: l.level != LinkLevel.disconnected && l.error == null),
                  CheckLine('WebSocket açıldı (hello)', done: l.helloReceived),
                  CheckLine('İlk telemetri paketi alındı', done: l.telemetryReceived),
                ]),
              ),
              const SizedBox(height: 8),
              const Text(
                'Uygulama robota hareket komutu göndermez; komutlar yalnız eldivenden gelir (şartname 5.1).',
                style: TextStyle(fontSize: 11, color: AppColors.mid),
              ),
            ],
          );
        },
      ),
    );
  }
}
