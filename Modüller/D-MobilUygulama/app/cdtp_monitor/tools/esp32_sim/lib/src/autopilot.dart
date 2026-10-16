import 'dart:math' as math;

import 'robot_model.dart';

/// Otomatik pilotun tek adımı: [action] bir kez çalışır, adım en az [minS]
/// saniye sürer; [waitIdle] ise robot hareketi bitene kadar da bekler.
class PilotStep {
  const PilotStep(this.label, {this.action, this.minS = 0, this.waitIdle = false});

  final String label;
  final void Function(RobotModel r)? action;
  final double minS;
  final bool waitIdle;

  /// Yalnız bekleme.
  const PilotStep.wait(this.label, this.minS)
      : action = null,
        waitIdle = false;
}

/// Robotu bir senaryo boyunca kendi kendine sürer (eldiven kullanmadan).
///
/// Senaryolar sonlu adım listeleridir; `wander` sonsuz bir üreteçtir.
/// Eldivenden gelen her komut pilotu durdurur (elle devralma).
class Autopilot {
  Autopilot(this.robot, {math.Random? random}) : _rnd = random ?? math.Random();

  final RobotModel robot;
  final math.Random _rnd;

  String? name;
  String? stepLabel;
  Iterator<PilotStep>? _steps;
  PilotStep? _current;
  double _t = 0;

  bool get active => _steps != null;

  /// Pilotun bildiği senaryolar → başlık.
  static const scenarios = {
    'auto_A': 'A: 30 s statik denge (hafif itmelerle)',
    'auto_B_forward': 'B: 1 m İLERİ',
    'auto_B_backward': 'B: 1 m GERİ',
    'auto_B_left': 'B: SOLA dön + 1 m',
    'auto_B_right': 'B: SAĞA dön + 1 m',
    'auto_C': 'C: rastgele noktadan istasyona yerleş + şarj',
    'auto_E': 'E: hedefe git, 5 s bekle, şarja yerleş',
    'auto_tour': 'Tur: A → B → C → E art arda',
    'wander': 'Serbest gezinti (pil azalınca şarja döner)',
  };

  bool start(String scenario) {
    final steps = switch (scenario) {
      'auto_A' => _taskA(),
      'auto_B_forward' => _taskB(0, 1),
      'auto_B_backward' => _taskB(0, -1),
      'auto_B_left' => _taskB(-90, 1),
      'auto_B_right' => _taskB(90, 1),
      'auto_C' => _taskC(),
      'auto_E' => _taskE(),
      'auto_tour' => _tour(),
      'wander' => _wander(),
      _ => null,
    };
    if (steps == null) return false;
    name = scenario;
    _steps = steps.iterator;
    _current = null;
    _next();
    return true;
  }

  void stop() {
    name = stepLabel = null;
    _steps = null;
    _current = null;
  }

  void tick(double dt) {
    final s = _current;
    if (s == null) return;
    _t += dt;
    if (robot.fallen) return stop();
    if (_t >= s.minS && (!s.waitIdle || robot.idle)) _next();
  }

  void _next() {
    final it = _steps;
    if (it == null || !it.moveNext()) return stop();
    final s = it.current;
    _current = s;
    stepLabel = s.label;
    _t = 0;
    s.action?.call(robot);
  }

  double _jitter(double around, double plusMinus) => around + (_rnd.nextDouble() * 2 - 1) * plusMinus;

  Iterable<PilotStep> _taskA() sync* {
    yield PilotStep('A: başlangıç noktasına al', action: (r) => r.reset());
    yield const PilotStep.wait('A: dengede bekliyor', 8);
    yield PilotStep('A: hafif itme', action: (r) => r.push(_jitter(5, 1)), minS: 10);
    yield PilotStep('A: ikinci itme', action: (r) => r.push(_jitter(-6, 1)), minS: 14);
  }

  /// [turn] derece dön, sonra [dir] yönünde ~1 m sür, dur.
  Iterable<PilotStep> _taskB(double turn, int dir) sync* {
    yield PilotStep('B: başlangıç noktasına al', action: (r) => r.reset());
    yield const PilotStep.wait('B: hazır, 2 s', 2);
    if (turn != 0) {
      yield PilotStep('B: ${turn > 0 ? 'sağa' : 'sola'} dön', action: (r) => r.rotate(turn), waitIdle: true);
    }
    final m = _jitter(1.0, 0.06);
    yield PilotStep('B: ${m.toStringAsFixed(2)} m sür', action: (r) => r.travel(m * dir), waitIdle: true);
    yield const PilotStep.wait('B: durdu, değerlendirme bekleniyor', 3);
  }

  Iterable<PilotStep> _taskC() sync* {
    final x0 = _jitter(0, 0.6), y0 = _jitter(0.1, 0.2);
    yield PilotStep('C: rastgele başlangıç (${x0.toStringAsFixed(1)}, ${y0.toStringAsFixed(1)})',
        action: (r) => r.reset(x0: x0, y0: y0, heading0: _rnd.nextDouble() * 360));
    yield const PilotStep.wait('C: hazır, 2 s', 2);
    yield PilotStep('C: istasyona sürüyor', action: (r) => r.dock(), waitIdle: true);
    yield const PilotStep.wait('C: yerleşti, şarj bekleniyor', 4);
  }

  Iterable<PilotStep> _taskE() sync* {
    yield PilotStep('E: başlangıç noktasına al', action: (r) => r.reset());
    yield const PilotStep.wait('E: kutu yüklendi, 2 s', 2);
    yield PilotStep('E: hedef bölgeye sürüyor', action: (r) => r.travel(_jitter(1.1, 0.03)), waitIdle: true);
    yield const PilotStep.wait('E: hedefte 5 s bekliyor', 6);
    yield PilotStep('E: şarj istasyonuna yerleşiyor', action: (r) => r.dock(), waitIdle: true);
    yield const PilotStep.wait('E: şarj bekleniyor', 4);
  }

  Iterable<PilotStep> _tour() sync* {
    yield* _taskA();
    yield* _taskB(0, 1);
    yield* _taskC();
    yield* _taskE();
  }

  /// Sınır içinde rastgele dolaşır; pil %20'nin altına inince şarja gider.
  Iterable<PilotStep> _wander() sync* {
    const maxX = 1.3, minY = -0.5, maxY = 2.0;
    while (true) {
      if (robot.batteryPct < 20) {
        yield PilotStep('Gezinti: pil düşük, şarja dönüyor', action: (r) => r.dock(), waitIdle: true);
        yield const PilotStep.wait('Gezinti: şarj oluyor', 20);
        continue;
      }
      final roll = _rnd.nextDouble();
      if (roll < 0.2) {
        yield PilotStep.wait('Gezinti: duruyor', 1 + _rnd.nextDouble() * 3);
      } else if (roll < 0.45) {
        final deg = [-90.0, 90.0, -45.0, 45.0, 180.0][_rnd.nextInt(5)];
        yield PilotStep('Gezinti: ${deg.round()}° dön', action: (r) => r.rotate(deg), waitIdle: true);
      } else {
        final m = (0.3 + _rnd.nextDouble() * 0.7) * (_rnd.nextDouble() < 0.8 ? 1 : -1);
        final h = robot.headingDeg * math.pi / 180;
        final tx = robot.x + math.sin(h) * m, ty = robot.y + math.cos(h) * m;
        if (tx.abs() > maxX || ty < minY || ty > maxY) {
          // Sınır dışına çıkacaktı: merkeze dön.
          var delta = math.atan2(-robot.x, 0.6 - robot.y) * 180 / math.pi - robot.headingDeg;
          delta = (delta + 540) % 360 - 180;
          yield PilotStep('Gezinti: sınırda, merkeze dönüyor', action: (r) => r.rotate(delta), waitIdle: true);
          yield PilotStep('Gezinti: merkeze sürüyor', action: (r) => r.travel(0.5), waitIdle: true);
        } else {
          yield PilotStep('Gezinti: ${m.toStringAsFixed(1)} m', action: (r) => r.travel(m), waitIdle: true);
        }
      }
    }
  }
}
