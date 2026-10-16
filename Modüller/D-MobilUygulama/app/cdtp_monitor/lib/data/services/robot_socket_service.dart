import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// ESP32-S3 (ya da simülatör) WebSocket bağlantısının ince sarmalayıcısı.
class RobotSocketService {
  static const connectTimeout = Duration(seconds: 5);

  WebSocketChannel? _ch;

  bool get isOpen => _ch != null;

  /// Bağlanır ve gelen metin çerçevelerinin akışını döner.
  /// Akış kapanınca bağlantı koptu demektir.
  Future<Stream<String>> connect(Uri uri) async {
    await close();
    final ch = WebSocketChannel.connect(uri);
    await ch.ready.timeout(connectTimeout);
    _ch = ch;
    return ch.stream.where((e) => e is String).cast<String>().transform(
          StreamTransformer.fromHandlers(handleDone: (sink) {
            if (identical(_ch, ch)) _ch = null;
            sink.close();
          }),
        );
  }

  void send(String text) => _ch?.sink.add(text);

  Future<void> close() async {
    final ch = _ch;
    _ch = null;
    await ch?.sink.close();
  }
}
