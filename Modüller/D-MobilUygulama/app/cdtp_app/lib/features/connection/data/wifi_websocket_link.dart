import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/robot_link.dart';

/// Wi-Fi uzerinden WebSocket baglantisi (birincil yol).
///
/// Tipik kurulum: ESP32 "CDTP-ROBOT" adinda kendi Wi-Fi agini (SoftAP) acar,
/// telefon bu aga baglanir, uygulama ws://192.168.4.1:80/ws adresine baglanir.
/// Simulatorle test ederken adres ws://<bilgisayar-ip>:8765/ws olur.
class WifiWebSocketLink implements RobotLink {
  WifiWebSocketLink(this.uri, {this.connectTimeout = const Duration(seconds: 4)});

  final Uri uri;
  final Duration connectTimeout;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _messages = StreamController<String>.broadcast();
  final _states = StreamController<TransportState>.broadcast();

  @override
  String get endpoint => uri.toString();

  @override
  Stream<String> get messages => _messages.stream;

  @override
  Stream<TransportState> get states => _states.stream;

  @override
  Future<void> connect() async {
    await _close();
    _states.add(TransportState.connecting);
    final channel = WebSocketChannel.connect(uri);
    try {
      // "ready" el sikisma tamamlaninca biter; ESP32 kapaliysa zaman asimina duser.
      await channel.ready.timeout(connectTimeout);
    } catch (e) {
      _states.add(TransportState.disconnected);
      rethrow;
    }
    _channel = channel;
    _sub = channel.stream.listen(
      (data) {
        if (data is String) _messages.add(data);
      },
      onDone: () {
        _channel = null;
        _states.add(TransportState.disconnected);
      },
      onError: (_) {
        _channel = null;
        _states.add(TransportState.disconnected);
      },
      cancelOnError: true,
    );
    _states.add(TransportState.connected);
  }

  @override
  void send(String json) => _channel?.sink.add(json);

  @override
  Future<void> disconnect() async {
    await _close();
    _states.add(TransportState.disconnected);
  }

  Future<void> _close() async {
    await _sub?.cancel();
    _sub = null;
    final c = _channel;
    _channel = null;
    if (c != null) {
      try {
        await c.sink.close().timeout(const Duration(seconds: 1));
      } catch (_) {
        // Kapanista olusan hatalar onemsiz.
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _close();
    await _messages.close();
    await _states.close();
  }
}
