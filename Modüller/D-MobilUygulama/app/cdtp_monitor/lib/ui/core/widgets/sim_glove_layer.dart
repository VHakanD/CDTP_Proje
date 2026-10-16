import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_scope.dart';
import '../../../data/services/sim_glove_service.dart';

/// Simülatöre bağlıyken klavyeyi sanal eldivene çevirir (W A S D / oklar,
/// boşluk = dur). Ekranda iz bırakmaz; yön, kamera ekranındaki yön göstergesinden okunur.
///
/// Kısa bas = bir adım (0,5 m ya da 90°). Basılı tut = sürekli sür; bırakınca
/// fren. Gerçek robota bağlıyken hiçbir şey yapmaz. Ekranda sürüş düğmesi
/// bilerek yok (şartname 5.1); telefondan sürmek için simülatör sayfasındaki
/// sürüş pedi kullanılır.
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

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
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
    _held = cmd;
    _heldSince = DateTime.now();
    _repeat = Timer.periodic(SimGloveLayer.repeatEvery, (_) {
      if (DateTime.now().difference(_heldSince!) > SimGloveLayer.holdAfter) {
        _glove.send(cmd);
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
    }
    _held = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
