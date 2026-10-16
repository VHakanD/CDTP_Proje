import 'package:flutter/foundation.dart';

import '../../../../data/repositories/robot_repository.dart';
import '../../../../domain/models/link_health.dart';

class RobotPreset {
  const RobotPreset(this.name, this.address, this.note);
  final String name;
  final String address;
  final String note;
}

/// Bağlantı ekranı (wireframe 01).
class ConnectionViewModel extends ChangeNotifier {
  ConnectionViewModel(this._robot) {
    _robot.link.addListener(notifyListeners);
  }

  static const presets = [
    RobotPreset('CDTP-Robot (ESP32-S3)', 'ws://192.168.4.1:80/ws', 'robotun Wi-Fi ağı: CDTP-ROBOT'),
    RobotPreset('Simülatör', 'ws://localhost:8765/ws', 'Docker / bilgisayar'),
    RobotPreset('Simülatör (emülatör)', 'ws://10.0.2.2:8765/ws', 'Android emülatöründen'),
  ];

  final RobotRepository _robot;
  String address = kIsWeb ? presets[1].address : presets[0].address;
  String? inputError;

  LinkState get link => _robot.link.value;
  bool get busy => link.level == LinkLevel.connecting;
  bool get verified => link.helloReceived && link.telemetryReceived && link.usable;

  void choose(String a) {
    address = a;
    inputError = null;
    notifyListeners();
  }

  /// `ws://` ya da `wss://` ve bir host içermeli.
  static String? validate(String a) {
    final u = Uri.tryParse(a.trim());
    if (u == null || !(u.scheme == 'ws' || u.scheme == 'wss') || u.host.isEmpty) {
      return 'Adres ws://IP:port/yol biçiminde olmalı';
    }
    return null;
  }

  Future<void> connect() async {
    inputError = validate(address);
    notifyListeners();
    if (inputError != null) return;
    await _robot.connect(Uri.parse(address.trim()));
  }

  Future<void> disconnect() => _robot.disconnect();

  @override
  void dispose() {
    _robot.link.removeListener(notifyListeners);
    super.dispose();
  }
}
