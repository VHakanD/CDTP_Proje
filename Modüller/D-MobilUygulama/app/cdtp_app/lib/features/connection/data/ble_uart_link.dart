import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/robot_link.dart';

/// Bluetooth LE baglantisi (ikincil yol).
///
/// ESP32 tarafinda Nordic UART Service (NUS) acilir. Wi-Fi ile AYNI JSON
/// mesajlari gonderilir; tek fark her mesajin sonuna '\n' eklenmesidir
/// (BLE paketleri bolunebildigi icin satir sonu ile birlestirilir).
///
///   Servis : 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
///   RX     : 6E400002-...  (uygulama -> robot, write)
///   TX     : 6E400003-...  (robot -> uygulama, notify)
///
/// Not: Web'de BLE desteklenmez; bu yol sadece Android/iOS'ta calisir.
class BleUartLink implements RobotLink {
  BleUartLink({required this.namePrefix, this.scanTimeout = const Duration(seconds: 8)});

  static final serviceUuid = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  static final rxUuid = Guid('6E400002-B5A3-F393-E0A9-E50E24DCCA9E');
  static final txUuid = Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E');

  /// Robotun BLE reklam adinin baslangici (orn. "CDTP").
  final String namePrefix;
  final Duration scanTimeout;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rx;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  final _buffer = StringBuffer();
  final _messages = StreamController<String>.broadcast();
  final _states = StreamController<TransportState>.broadcast();

  @override
  String get endpoint => _device == null
      ? 'BLE: "$namePrefix*"'
      : 'BLE: ${_device!.platformName} (${_device!.remoteId.str})';

  @override
  Stream<String> get messages => _messages.stream;

  @override
  Stream<TransportState> get states => _states.stream;

  @override
  Future<void> connect() async {
    if (kIsWeb) {
      throw UnsupportedError('Web tarayıcıda BLE desteklenmiyor. Wi-Fi seçin.');
    }
    if (!await FlutterBluePlus.isSupported) {
      throw UnsupportedError('Bu cihazda Bluetooth LE yok.');
    }
    _states.add(TransportState.connecting);
    // Yeniden baglanmada eski abonelikleri birak.
    await _notifySub?.cancel();
    await _connSub?.cancel();
    try {
      final device = _device ?? await _scan();
      _device = device;

      await device.connect(timeout: const Duration(seconds: 8));
      // Android'de varsayilan MTU 23 bayt; uzun JSON icin buyutulur.
      if (defaultTargetPlatform == TargetPlatform.android) {
        await device.requestMtu(247);
      }

      final services = await device.discoverServices();
      final uart = services.firstWhere(
        (s) => s.uuid == serviceUuid,
        orElse: () => throw StateError('Robotta UART servisi bulunamadı.'),
      );
      final tx = uart.characteristics.firstWhere((c) => c.uuid == txUuid);
      _rx = uart.characteristics.firstWhere((c) => c.uuid == rxUuid);

      await tx.setNotifyValue(true);
      _notifySub = tx.onValueReceived.listen(_onBytes);
      _connSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          _states.add(TransportState.disconnected);
        }
      });
      _states.add(TransportState.connected);
    } catch (_) {
      _states.add(TransportState.disconnected);
      rethrow;
    }
  }

  /// Adi namePrefix ile baslayan ilk cihazi bulur.
  Future<BluetoothDevice> _scan() async {
    final completer = Completer<BluetoothDevice>();
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName;
        if (name.startsWith(namePrefix) && !completer.isCompleted) {
          completer.complete(r.device);
        }
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: scanTimeout);
      return await completer.future.timeout(scanTimeout);
    } on TimeoutException {
      throw StateError('"$namePrefix" adlı BLE cihazı bulunamadı.');
    } finally {
      await sub.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  /// BLE paketlerini birlestirip '\n' ile ayrilmis tam JSON satirlarini yayinlar.
  void _onBytes(List<int> bytes) {
    _buffer.write(utf8.decode(bytes, allowMalformed: true));
    var text = _buffer.toString();
    var idx = text.indexOf('\n');
    while (idx >= 0) {
      final line = text.substring(0, idx).trim();
      if (line.isNotEmpty) _messages.add(line);
      text = text.substring(idx + 1);
      idx = text.indexOf('\n');
    }
    _buffer
      ..clear()
      ..write(text);
  }

  /// BLE yazmalari sirayla yapilir; bir onceki bitmeden digeri baslamaz.
  Future<void> _writeQueue = Future.value();

  @override
  void send(String json) {
    final rx = _rx;
    final device = _device;
    if (rx == null || device == null) return;
    final data = utf8.encode('$json\n');
    // MTU'dan buyuk mesajlar parcalara bolunur.
    final chunk = (device.mtuNow - 3).clamp(20, 244).toInt();
    _writeQueue = _writeQueue.then((_) async {
      try {
        for (var i = 0; i < data.length; i += chunk) {
          final end = (i + chunk < data.length) ? i + chunk : data.length;
          await rx.write(data.sublist(i, end), withoutResponse: rx.properties.writeWithoutResponse);
        }
      } catch (_) {
        // Baglanti koptuysa yazma hatasi onemsiz; durum akisi kopmayi bildirir.
      }
    });
  }

  @override
  Future<void> disconnect() async {
    await _notifySub?.cancel();
    await _connSub?.cancel();
    _notifySub = null;
    _connSub = null;
    _rx = null;
    _buffer.clear();
    await _device?.disconnect();
    _states.add(TransportState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _messages.close();
    await _states.close();
  }
}
