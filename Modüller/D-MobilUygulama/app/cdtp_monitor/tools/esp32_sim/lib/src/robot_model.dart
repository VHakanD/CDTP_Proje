import 'dart:math' as math;

/// Robot ESP32-S3'ün fiziksel davranışının modeli.
///
/// Koordinatlar metre; başlangıç (0, 0); yön 0° = ileri (+y), saat yönünde artar.
/// Eldiven komutları: ileri/geri ≈ 0,5 m, dönüş ≈ 90°, dur. Komut basılı
/// tutuldukça (tekrarlandıkça) robot durmadan sürer; `stop` yumuşak frenler.
///
/// Hız ve dönüş ivmeli: kalkışta hızlanır, hedefe yaklaşınca yavaşlar.
/// Eğim iki tekerlekli dengeleyici gibi davranır: ivmede öne/arkaya yatar,
/// sabit hızda hafifçe eğik kalır, durunca yavaş salınımla dengelenir.
class RobotModel {
  RobotModel({math.Random? random}) : _rnd = random ?? math.Random(42);

  static const stepM = 0.5;
  static const speedMps = 0.25;
  static const accelMps2 = 1.0;
  static const turnDeg = 90.0;
  static const turnDegPerS = 90.0;
  static const turnAccelDegPs2 = 360.0;
  static const station = (x: 0.0, y: 1.2);
  static const dockSpeedMps = 0.2;
  static const chargeDelayS = 2.0;
  static const startBatteryPct = 78.0;

  /// Pil tüketimi (%/s): beklerken denge motorları, sürüşte daha fazla.
  static const drainIdle = 0.01, drainMoving = 0.04, drainTurning = 0.03, chargeRate = 0.15;

  final math.Random _rnd;

  double x = 0, y = 0, headingDeg = 0;
  double tiltDeg = 0;
  double batteryPct = startBatteryPct;
  bool charging = false;
  bool docked = false;
  bool boxPresent = true;
  bool visible = true;
  bool fallen = false;
  String? lastCmd;
  int lastCmdSeq = 0;
  int seq = 0;
  double uptimeS = 0;

  /// Anlık doğrusal hız (m/s, + ileri) ve dönüş hızı (°/s, + sağ).
  double speed = 0, turnRate = 0;

  double _remainM = 0; // + ileri, - geri
  double _remainDeg = 0; // + sağ, - sol
  bool _docking = false;
  double _dockedFor = 0;
  double _kick = 0; // itme / toparlanma için ek eğim
  double _accel = 0;
  double _sway = 0; // yavaş denge salınımı (filtrelenmiş gürültü)

  /// `idle`, `balancing`, `moving`, `turning`, `recovering`, `docking`, `docked`, `fallen`.
  String get state {
    if (fallen) return 'fallen';
    if (docked) return 'docked';
    if (_docking) return 'docking';
    if (_kick.abs() > 4) return 'recovering';
    if (_remainDeg != 0 || turnRate.abs() > 1) return 'turning';
    if (_remainM != 0 || speed.abs() > 0.01) return 'moving';
    return 'balancing';
  }

  /// Eldivenden gelen komut (`forward`, `backward`, `left`, `right`, `stop`).
  void command(String cmd) {
    if (fallen) return;
    lastCmd = cmd;
    lastCmdSeq++;
    switch (cmd) {
      case 'forward':
        travel(stepM);
      case 'backward':
        travel(-stepM);
      case 'right':
        rotate(turnDeg);
      case 'left':
        rotate(-turnDeg);
      case 'stop':
        _docking = false;
        _remainDeg = 0;
        // Fren mesafesi kadar devam et (ani durma yok).
        _remainM = speed * speed / (2 * accelMps2) * speed.sign;
    }
  }

  /// [m] metre sür (+ ileri, - geri). Otomatik pilot tam mesafe için kullanır.
  void travel(double m) {
    if (fallen) return;
    _undock();
    _remainM = m;
    _remainDeg = 0;
  }

  /// [deg] derece dön (+ sağ, - sol).
  void rotate(double deg) {
    if (fallen) return;
    _undock();
    _remainDeg = deg;
    _remainM = 0;
    speed = 0;
  }

  /// Otonom şarj yerleşmesi (Modül C): istasyona doğru sür, otur, 2 s sonra şarj.
  void dock() {
    if (fallen || docked) return;
    _remainM = 0;
    _remainDeg = 0;
    _docking = true;
  }

  void _undock() {
    docked = false;
    charging = false;
    _docking = false;
    _dockedFor = 0;
  }

  /// Hareket bitti mi (otomatik pilot adım beklerken kullanır).
  bool get idle => !_docking && _remainM == 0 && _remainDeg == 0 && speed.abs() < 0.01 && turnRate.abs() < 1;

  void dropBox() => boxPresent = false;

  /// Dışarıdan itme: eğim artar, robot toparlanır.
  void push(double deg) => _kick += deg;

  void knockOver() {
    fallen = true;
    _remainM = 0;
    _remainDeg = 0;
    speed = turnRate = 0;
    _docking = false;
  }

  /// Konumu sıfırla; pil aynen kalır (gerçek robotta olduğu gibi).
  void reset({double x0 = 0, double y0 = 0, double heading0 = 0}) {
    x = x0;
    y = y0;
    headingDeg = heading0;
    tiltDeg = 0;
    charging = docked = fallen = _docking = false;
    boxPresent = visible = true;
    _remainM = _remainDeg = _kick = _dockedFor = _accel = _sway = speed = turnRate = 0;
    lastCmd = null;
  }

  void step(double dt) {
    uptimeS += dt;
    if (fallen) {
      tiltDeg = 80;
      return;
    }

    final v0 = speed;
    if (_remainDeg != 0) {
      _stepTurn(dt);
    } else if (_remainM != 0) {
      _stepDrive(dt, _remainM, speedMps);
    } else if (_docking) {
      _stepDock(dt);
    } else {
      // Komut yok: kalan hızı frenle.
      speed = _approach(speed, 0, accelMps2 * dt);
      _advance(speed * dt);
      turnRate = _approach(turnRate, 0, turnAccelDegPs2 * dt);
    }
    _accel = (speed - v0) / dt;

    if (docked) {
      _dockedFor += dt;
      if (_dockedFor >= chargeDelayS) charging = true;
    }

    final drain = switch (state) {
      'moving' || 'docking' => drainMoving,
      'turning' => drainTurning,
      _ => drainIdle,
    };
    batteryPct = (batteryPct + (charging ? chargeRate : -drain) * dt).clamp(0, 100);

    // Denge: ivmeye ters yatma + hızla orantılı eğim + yavaş salınım + itme
    _kick *= math.exp(-dt / 1.2);
    final a = 1 - math.exp(-dt / 0.8);
    _sway += ((_rnd.nextDouble() - 0.5) * 4 - _sway) * a;
    final noise = (_rnd.nextDouble() - 0.5) * 0.4;
    final damp = docked ? 0.2 : 1.0;
    tiltDeg = speed / speedMps * 3.0 + _accel * 1.5 + _kick + (_sway + noise) * damp;
  }

  void _stepTurn(double dt) {
    final left = _remainDeg.abs();
    final maxByBrake = math.sqrt(2 * turnAccelDegPs2 * left);
    final target = math.min(turnDegPerS, maxByBrake);
    final rate = _approach(turnRate.abs(), target, turnAccelDegPs2 * dt);
    final d = math.min(math.max(rate, 5.0) * dt, left) * _remainDeg.sign;
    turnRate = rate * _remainDeg.sign;
    headingDeg = (headingDeg + d) % 360;
    _remainDeg -= d;
    if (_remainDeg.abs() < 1e-6) _remainDeg = 0;
  }

  void _stepDrive(double dt, double remain, double vmax) {
    final dir = remain.sign;
    if (speed != 0 && speed.sign != dir) {
      // Ters yöne geçmeden önce fren: robot bu sırada kayarak ilerler.
      speed = _approach(speed, 0, accelMps2 * dt);
      _advance(speed * dt);
      return;
    }
    final left = remain.abs();
    final maxByBrake = math.sqrt(2 * accelMps2 * left);
    final target = math.min(vmax, maxByBrake) * dir;
    speed = _approach(speed, target, accelMps2 * dt);
    // Yön değişiminde önce durmak gerekir; en az 2 cm/s ile son santimleri bitir.
    final v = speed.sign == dir ? math.max(speed.abs(), 0.02) : 0.0;
    final d = math.min(v * dt, left) * dir;
    _advance(d);
    _remainM -= d;
    if (_remainM.abs() < 1e-6) {
      _remainM = 0;
      if (speed.abs() < 0.05) speed = 0;
    }
  }

  void _stepDock(double dt) {
    final dx = station.x - x, dy = station.y - y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist > 1e-3) {
      headingDeg = math.atan2(dx, dy) * 180 / math.pi % 360;
      final target = math.min(dockSpeedMps, math.sqrt(2 * accelMps2 * dist));
      speed = _approach(speed, target, accelMps2 * dt);
      _advance(math.min(math.max(speed, 0.02) * dt, dist));
    } else {
      speed = 0;
      _docking = false;
      docked = true;
      _dockedFor = 0;
    }
  }

  void _advance(double d) {
    if (d == 0) return;
    final h = headingDeg * math.pi / 180;
    x += math.sin(h) * d;
    y += math.cos(h) * d;
  }

  static double _approach(double v, double target, double maxDelta) =>
      v < target ? math.min(v + maxDelta, target) : math.max(v - maxDelta, target);

  Map<String, Object?> telemetry() => {
        'type': 'telemetry',
        'seq': ++seq,
        'uptime_ms': (uptimeS * 1000).round(),
        'battery_pct': double.parse(batteryPct.toStringAsFixed(1)),
        'tilt_deg': double.parse(tiltDeg.toStringAsFixed(2)),
        'charging': charging,
        'docked': docked,
        'state': state,
        'box_present': boxPresent,
        'last_cmd': ?lastCmd,
        'last_cmd_seq': lastCmdSeq,
      };

  Map<String, Object?> pose() => {
        'type': 'sim_pose',
        'x_m': double.parse(x.toStringAsFixed(3)),
        'y_m': double.parse(y.toStringAsFixed(3)),
        'heading_deg': double.parse(headingDeg.toStringAsFixed(1)),
        'speed_mps': double.parse(speed.toStringAsFixed(3)),
        'visible': visible,
      };
}
