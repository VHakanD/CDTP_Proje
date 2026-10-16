import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../app_scope.dart';
import '../../../../domain/models/motion.dart';
import '../../../core/camera/camera_surface.dart';
import '../../../core/camera/frame_mapping.dart';
import '../../../core/format.dart';
import '../../../core/session_store.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/direction_indicator.dart';
import '../../../core/widgets/link_badge.dart';
import '../view_models/camera_hud_view_model.dart';

/// 05 · Kamera + HUD (Varyant B): yön göstergesi sol kenarda, bilgi şeridi
/// altta (9:16'da görüntünün üstünde). Görüntü 1:1 varsayılan.
class CameraHudScreen extends StatefulWidget {
  const CameraHudScreen({super.key});

  @override
  State<CameraHudScreen> createState() => _CameraHudScreenState();
}

class _CameraHudScreenState extends State<CameraHudScreen> with WidgetsBindingObserver {
  CameraHudViewModel? _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wakelock(true); // test sürerken ekran kararmasın
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null) return;
    final s = AppScope.of(context);
    _vm = CameraHudViewModel(session: s.session, robot: s.robot, reports: s.reports, tracking: s.tracking)..init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wakelock(false);
    _vm?.dispose();
    super.dispose();
  }

  /// Arka plana geçince kamerayı bırak (kayıt sürmüyorsa), dönünce yeniden aç.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final vm = _vm;
    if (vm == null) return;
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        unawaited(vm.pause());
      case AppLifecycleState.resumed:
        unawaited(vm.resume());
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break; // izin penceresi de "inactive" yapar; kamerayı orada kapatma
    }
  }

  /// Eklenti olmayan ortamlarda (widget testleri) sessizce geçer.
  static void _wakelock(bool on) {
    try {
      unawaited((on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((Object _) {}));
    } catch (_) {}
  }

  /// Kayıt sürerken geri engellenir; mühürlenmiş test geri tuşuyla sonuca gider.
  void _onBlockedPop(CameraHudViewModel vm) {
    final r = vm.report;
    if (r != null) {
      context.go('/result/${r.id}');
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Kayıt sürerken çıkılamaz — önce testi bitirin')));
  }

  Future<void> _confirmStop() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Test bitirilsin mi?'),
        content: const Text('Kayıt kapanır ve sonuç mühürlenir. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Devam et')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Testi bitir')),
        ],
      ),
    );
    if (ok == true) await _vm!.stop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final task = vm.session.task;
        final tall = vm.ratio == FrameRatio.tall;
        return PopScope(
          canPop: !vm.recording && vm.phase != HudPhase.sealing && vm.report == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onBlockedPop(vm);
          },
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(children: [
                  Row(children: [
                    _RecLabel(vm),
                    const Spacer(),
                    LinkBadge(vm.link, compact: true),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Text(task == null ? '' : 'Görev ${task.module} · ${task.label}',
                          style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),
                    SegmentedButton<FrameRatio>(
                      key: const Key('ratio-selector'),
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: [
                        for (final r in FrameRatio.values) ButtonSegment(value: r, label: Text(r.label)),
                      ],
                      selected: {vm.ratio},
                      onSelectionChanged: (s) => vm.setRatio(s.first),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: CameraSurface(
                        key: const Key('camera-surface'),
                        tracking: vm.tracking,
                        aspect: vm.ratio.aspect,
                        overlay: (map) => _overlay(vm, map, tall),
                      ),
                    ),
                  ),
                  if (!tall) ...[const SizedBox(height: 8), _InfoStrip(vm)],
                  if (vm.autoEnded && vm.phase == HudPhase.ended) ...[
                    const SizedBox(height: 8),
                    Text('Otomatik bitiş: ${task?.endRule}.', style: const TextStyle(fontSize: 12, color: AppColors.warn)),
                  ],
                  if (vm.error != null)
                    Text(vm.error!, style: const TextStyle(fontSize: 12, color: AppColors.fail)),
                  if (vm.trackingError != null)
                    Row(children: [
                      Expanded(
                        child: Text(vm.trackingError!,
                            key: const Key('tracking-error'),
                            style: const TextStyle(fontSize: 12, color: AppColors.fail)),
                      ),
                      TextButton(onPressed: vm.retry, child: const Text('Tekrar dene')),
                    ]),
                  const SizedBox(height: 8),
                  _ActionButton(vm, onStop: _confirmStop),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _overlay(CameraHudViewModel vm, FrameMapping map, bool tall) {
    final m = vm.motion;
    final start = vm.session.scene.start;
    final box = m.center == null ? null : Rect.fromCenter(center: map.toDisplay(m.center!), width: 58, height: 46);
    return [
      CustomPaint(painter: _TrailPainter([for (final p in m.trail) map.toDisplay(p)])),
      if (start != null)
        Positioned(
          left: map.toDisplay(start).dx - 6,
          top: map.toDisplay(start).dy - 9,
          child: const Text('×', style: TextStyle(fontSize: 14)),
        ),
      if (box != null)
        Positioned.fromRect(
          rect: box,
          child: Container(
            key: const Key('track-box'),
            decoration: BoxDecoration(
              border: Border.all(
                color: m.quality == TrackQuality.visible ? Colors.white : Colors.white54,
                width: 2,
              ),
            ),
          ),
        ),
      if (box != null && m.quality != TrackQuality.lost)
        Positioned(
          left: box.center.dx - 80,
          width: 160,
          top: box.top - 18,
          child: Text(
            m.quality == TrackQuality.weak
                ? 'Robot zor görünüyor %${(m.confidence * 100).round()}'
                : 'Robot görünüyor %${(m.confidence * 100).round()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, shadows: [Shadow(blurRadius: 3)]),
          ),
        ),
      if (m.quality == TrackQuality.lost)
        Center(
          child: Container(
            key: const Key('lost-banner'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              border: Border.all(color: AppColors.warn, width: 2),
            ),
            child: const Text('! Robot kayboldu', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      Positioned(left: 8, top: 0, bottom: 0, child: Center(child: DirectionIndicator(m.heading))),
      if (tall) Positioned(left: 8, right: 8, bottom: 8, child: _InfoStrip(vm, overlay: true)),
    ];
  }
}

class _RecLabel extends StatelessWidget {
  const _RecLabel(this.vm);
  final CameraHudViewModel vm;

  @override
  Widget build(BuildContext context) {
    final (dot, text, color) = switch (vm.phase) {
      HudPhase.recording => ('●', 'Kayıt ${fmtClock(vm.elapsed).substring(0, 5)}', AppColors.fail),
      HudPhase.sealing => ('◌', 'Mühürleniyor…', AppColors.mid),
      HudPhase.ended => ('○', 'Kayıt kapandı', AppColors.mid),
      HudPhase.ready => ('○', 'Kayıt yok', AppColors.mid),
    };
    return Text.rich(TextSpan(children: [
      TextSpan(text: '$dot ', style: TextStyle(color: color)),
      TextSpan(text: text),
    ]), style: const TextStyle(fontSize: 12));
  }
}

/// Süre · Pil · Eğim / Durum · Mesafe şeridi.
class _InfoStrip extends StatelessWidget {
  const _InfoStrip(this.vm, {this.overlay = false});
  final CameraHudViewModel vm;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final t = vm.telemetry;
    final m = vm.motion;
    final stale = !vm.link.usable;
    Widget cell(String k, String v) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k, style: const TextStyle(fontSize: 10, color: AppColors.mid)),
              Text(v, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
    return Container(
      key: Key(overlay ? 'info-strip-overlay' : 'info-strip'),
      decoration: BoxDecoration(
        color: overlay ? Colors.black.withValues(alpha: 0.6) : AppColors.surface,
        border: Border.all(color: overlay ? Colors.white38 : AppColors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            cell('Süre', fmtClock(vm.elapsed)),
            const VerticalDivider(width: 1),
            cell('Pil', t == null ? '—' : '%${fmtNum(t.batteryPct, 0)} · ${t.charging ? 'şarjda' : 'yok'}'),
            const VerticalDivider(width: 1),
            cell('Eğim', t == null ? '—' : '${fmtSigned(t.tiltDeg)}°${stale ? ' (eski)' : ''}'),
          ]),
        ),
        const Divider(height: 1),
        Row(children: [
          cell('Durum', m.state.label),
          cell('Mesafe', m.distanceM == null ? '— / 0,8–1,2 m' : '${fmtNum(m.distanceM!, 2)} m / 0,8–1,2'),
        ]),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(this.vm, {required this.onStop});
  final CameraHudViewModel vm;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) => switch (vm.phase) {
        HudPhase.ready => FilledButton.icon(
            key: const Key('start-test'),
            onPressed: vm.canStart ? vm.start : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(vm.canStart ? 'Testi başlat' : 'Robot ve bağlantı bekleniyor'),
          ),
        HudPhase.recording => FilledButton.icon(
            key: const Key('stop-test'),
            onPressed: onStop,
            icon: const Icon(Icons.stop),
            label: const Text('Testi bitir'),
          ),
        HudPhase.sealing => const FilledButton(onPressed: null, child: Text('Sonuç mühürleniyor…')),
        HudPhase.ended => FilledButton(
            onPressed: vm.report == null ? null : () => context.go('/result/${vm.report!.id}'),
            child: const Text('Sonucu gör'),
          ),
      };
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.pts);
  final List<Offset> pts;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;
    for (var i = 1; i < pts.length; i += 2) {
      c.drawLine(pts[i - 1], pts[i], p); // kesikli görünüm için atlamalı
    }
  }

  @override
  bool shouldRepaint(_TrailPainter o) => true;
}
