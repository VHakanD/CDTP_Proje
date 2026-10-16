import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_scope.dart';
import '../../../core/camera/camera_surface.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/wf_parts.dart';
import '../view_models/scene_view_model.dart';

/// 04 · Kamera kalibrasyonu / sahne hazırlama.
class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key});

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  SceneViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final s = AppScope.of(context);
    _vm = SceneViewModel(s.session, s.tracking, s.robot)..init();
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return Scaffold(
      appBar: AppBar(title: const Text('Sahne hazırlama')),
      body: ListenableBuilder(
        listenable: Listenable.merge([vm, vm.session, vm.tracking]),
        builder: (context, _) {
          final s = vm.session.scene;
          final task = vm.session.task;
          final hint = switch (vm.mode) {
            TapMode.p1 => 'İşaretin bir ucuna (P1) dokunun',
            TapMode.p2 => 'İşaretin diğer ucuna (P2) dokunun',
            TapMode.zoneA => 'Hedef bölgenin bir köşesine dokunun',
            TapMode.zoneB => 'Karşı köşeye dokunun',
            TapMode.none => null,
          };
          return WfPage(
            bottom: Column(mainAxisSize: MainAxisSize.min, children: [
              if (!vm.ready)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Eksik: ${vm.missing.join(' · ')}',
                      style: const TextStyle(fontSize: 12, color: AppColors.warn)),
                ),
              FilledButton(
                onPressed: vm.ready
                    ? () {
                        vm.captureStart();
                        context.push('/camera');
                      }
                    : null,
                child: const Text('Kamera ekranına geç'),
              ),
            ]),
            children: [
              Row(children: [
                Expanded(child: Text(task == null ? '' : 'Görev ${task.module} · ${task.label}')),
                if (vm.tracking.isSim) const Pill('simülatör'),
              ]),
              const SizedBox(height: 8),
              CameraSurface(
                tracking: vm.tracking,
                aspect: 1,
                onTapSensor: vm.onTap,
                overlay: (map) => [
                  if (s.p1 != null && s.p2 != null)
                    CustomPaint(painter: _LinePainter(map.toDisplay(s.p1!), map.toDisplay(s.p2!))),
                  if (s.targetZone != null)
                    Positioned.fromRect(
                      rect: map.rectToDisplay(s.targetZone!),
                      child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.white70, width: 1.5))),
                    ),
                  if (vm.lastSample?.center != null)
                    Positioned.fromRect(
                      rect: Rect.fromCenter(center: map.toDisplay(vm.lastSample!.center!), width: 52, height: 40),
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: vm.robotVisible ? Colors.white : Colors.white38, width: 2)),
                      ),
                    ),
                  if (hint != null)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.black54,
                        child: Text(hint, textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
              if (vm.tracking.error != null) ...[
                const SizedBox(height: 8),
                WfBox(dashed: true, child: Text(vm.tracking.error!, style: const TextStyle(fontSize: 12))),
              ],
              if (vm.tracking.isSim) ...[
                const SizedBox(height: 8),
                OutlinedButton(onPressed: vm.useSimScene, child: const Text('Simülatör sahnesini kullan')),
              ],
              const SectionLabel('Adımlar'),
              WfBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: s.phoneFixed,
                    onChanged: (v) => vm.setPhoneFixed(v ?? false),
                    title: const Text('1. Telefon sabit, alan kadrajda'),
                  ),
                  CheckLine(
                    '2. Ölçek: P1–P2 = ${fmtNum(s.markerLengthM, 2)} m → '
                    '${s.unitsPerMeter == null ? '—' : '${fmtNum(s.unitsPerMeter!, 3)} birim/m'}'
                    '${task?.needsScale == true ? '' : ' (bu görevde isteğe bağlı)'}',
                    done: s.hasScale,
                  ),
                  Row(children: [
                    TextButton(onPressed: () => vm.startMode(TapMode.p1), child: const Text('P1–P2 seç')),
                    const Spacer(),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        initialValue: fmtNum(s.markerLengthM, 2),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(isDense: true, suffixText: 'm'),
                        onChanged: (t) => vm.setMarkerLength(double.tryParse(t.replaceAll(',', '.')) ?? 0),
                      ),
                    ),
                  ]),
                  CheckLine('3. Robot kadrajda', done: vm.robotVisible),
                  CheckLine(
                    '4. Hedef / şarj bölgesi${task?.needsTargetZone == true ? '' : ' (bu görevde gerekmez)'}',
                    done: s.targetZone != null,
                  ),
                  TextButton(onPressed: () => vm.startMode(TapMode.zoneA), child: const Text('Bölgeyi çiz')),
                ]),
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: vm.reset, child: const Text('Sıfırla')),
            ],
          );
        },
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.a, this.b);
  final Offset a, b;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    c.drawLine(a, b, p);
    c.drawCircle(a, 5, p);
    c.drawCircle(b, 5, p);
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.a != a || o.b != b;
}
