import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Yalnız simülatörle çalışırken: eldiven ESP32-S3'ünü taklit eden **ayrı**
/// kanal (`/glove`). Uygulamanın robot kanalına (`/ws`) hareket komutu
/// göndermez; şartname 5.1 (uygulama robotu yönetmez) korunur.
/// Gerçek robotta bu servis hiç bağlanmaz.
class SimGloveService {
  WebSocketChannel? _ch;
  Uri? _uri;
  int _seq = 0;

  /// Bağlıyken son gönderilen komut (rozette gösterilir); bağlı değilken null.
  final lastCmd = ValueNotifier<String?>(null);
  final connected = ValueNotifier<bool>(false);

  /// Robot adresinden eldiven adresini türetir: ws://host:port/glove
  static Uri gloveUriFor(Uri robot) =>
      Uri(scheme: robot.scheme, host: robot.host, port: robot.hasPort ? robot.port : null, path: '/glove');

  Future<void> attach(Uri robot) async {
    final uri = gloveUriFor(robot);
    if (_uri == uri) return; // bağlı ya da bağlanıyor
    await detach();
    _uri = uri;
    try {
      final ch = WebSocketChannel.connect(uri);
      await ch.ready;
      if (_uri != uri || _ch != null) {
        await ch.sink.close(); // bu arada adres değişti ya da kapatıldı
        return;
      }
      _ch = ch;
      connected.value = true;
      ch.stream.listen((_) {}, onDone: () {
        if (identical(_ch, ch)) {
          _ch = null;
          _uri = null;
          connected.value = false;
        }
      }, onError: (_) {});
    } catch (_) {
      if (_uri == uri) _uri = null; // sonraki bağlantı değişiminde yeniden dener
      connected.value = _ch != null;
    }
  }

  Future<void> detach() async {
    final ch = _ch;
    _ch = null;
    _uri = null;
    connected.value = false;
    lastCmd.value = null;
    await ch?.sink.close();
  }

  void send(String cmd) {
    final ch = _ch;
    if (ch == null) return;
    ch.sink.add(jsonEncode({'type': 'glove_cmd', 'cmd': cmd, 'seq': ++_seq}));
    lastCmd.value = cmd;
  }
}
