import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_scope.dart';
import '../../../data/services/sim_glove_service.dart';
import '../theme.dart';

/// Simülatöre bağlıyken klavyeyi sanal eldivene çevirir (W A S D / oklar,
/// boşluk = dur) ve sağ altta küçük bir rozet gösterir.
///
/// Kısa bas = bir adım (0,5 m ya da 90°). Basılı tut = sürekli sür; bırakınca
/// fren. Gerçek robota bağlıyken hiçbir şey yapmaz.
class SimGloveLayer extends StatefulWidget {
  const SimGloveLayer({super.key, required this.child, this.service});

  final Widget child;
  final SimGloveService? service;

  static const holdAfter = Duration(milliseconds: 300);
  static const repeatEvery = Duration(milliseconds: 200);

  static final keys = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.keyW: 'forward',
    LogicalKeyboardKey.arrowUp: 'forward',
    LogicalKeyboardKey.keyS: 'backward',
    LogicalKeyboardKey.arrowDown: 'backward',
    LogicalKeyboardKey.keyA: 'left',
    LogicalKeyboardKey.arrowLeft: 'left',
    LogicalKeyboardKey.keyD: 'right',
    LogicalKeyboardKey.arrowRight: 'right',
    LogicalKeyboardKey.space: 'stop',
  };

  @override
  State<SimGloveLayer> createState() => _SimGloveLayerState();
}

class _SimGloveLayerState extends State<SimGloveLayer> {
  late final SimGloveService _glove = widget.service ?? SimGloveService();
  AppScope? _scope;
  String? _held;
  DateTime? _heldSince;
  Timer? _repeat;

  /// Rozet yalnız bağlanınca ve tuşa basınca kısa süre görünür (alt düğmeleri örtmesin).
  final _badge = ValueNotifier<bool>(false);
  Timer? _hide;

  void _flash([Duration d = const Duration(milliseconds: 1800)]) {
    _badge.value = true;
    _hide?.cancel();
    _hide = Timer(d, () => _badge.value = false);
  }

  void _onConnected() {
    if (_glove.connected.value) _flash(const Duration(seconds: 4));
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _glove.connected.addListener(_onConnected);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    if (!identical(scope, _scope)) {
      _scope?.robot.link.removeListener(_syncLink);
      _scope = scope;
      scope.robot.link.addListener(_syncLink);
      _syncLink();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _scope?.robot.link.removeListener(_syncLink);
    _repeat?.cancel();
    _hide?.cancel();
    _glove.connected.removeListener(_onConnected);
    _glove.detach();
    super.dispose();
  }

  bool get _active => _glove.connected.value;

  void _syncLink() {
    final robot = _scope?.robot;
    if (robot == null) return;
    final uri = robot.link.value.uri;
    if (uri != null && robot.isSimulator && robot.link.value.usable) {
      _glove.attach(uri);
    } else if (uri == null || !robot.isSimulator) {
      _release();
      _glove.detach();
    }
  }

  bool _typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null &&
        (ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null);
  }

  bool _onKey(KeyEvent e) {
    final cmd = SimGloveLayer.keys[e.logicalKey];
    if (cmd == null || !_active || _typing()) return false;
    switch (e) {
      case KeyDownEvent():
        _press(cmd);
      case KeyUpEvent():
        if (_held == cmd) _release();
      case KeyRepeatEvent():
        break; // kendi tekrar zamanlayıcımız var
    }
    return true;
  }

  void _press(String cmd) {
    if (_held == cmd) return;
    _release();
    _glove.send(cmd);
    _flash();
    _held = cmd;
    _heldSince = DateTime.now();
    _repeat = Timer.periodic(SimGloveLayer.repeatEvery, (_) {
      if (DateTime.now().difference(_heldSince!) > SimGloveLayer.holdAfter) {
        _glove.send(cmd);
        _flash();
      }
    });
  }

  void _release() {
    final cmd = _held;
    if (cmd == null) return;
    _repeat?.cancel();
    _repeat = null;
    final long = DateTime.now().difference(_heldSince!) > SimGloveLayer.holdAfter;
    if (long && cmd != 'stop') {
      _glove.send('stop');
      _flash();
    }
    _held = null;
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          widget.child,
          Positioned(
            right: 8,
            bottom: 8,
            child: IgnorePointer(
              child: ListenableBuilder(
                listenable: Listenable.merge([_glove.connected, _badge]),
                builder: (_, _) => AnimatedOpacity(
                  opacity: _glove.connected.value && _badge.value ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: _Badge(lastCmd: _glove.lastCmd),
                ),
              ),
            ),
          ),
        ],
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.lastCmd});
  final ValueListenable<String?> lastCmd;

  static const _labels = {
    'forward': '▲ ileri',
    'backward': '▼ geri',
    'left': '◀ sol',
    'right': 'sağ ▶',
    'stop': '■ dur',
  };

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface.withValues(alpha: 0.92),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.hair),
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ValueListenableBuilder<String?>(
            valueListenable: lastCmd,
            builder: (_, cmd, _) => Text(
              'sanal eldiven · W A S D${cmd == null ? '' : ' · ${_labels[cmd]}'}',
              style: const TextStyle(fontSize: 11, color: AppColors.mid),
            ),
          ),
        ),
      );
}
