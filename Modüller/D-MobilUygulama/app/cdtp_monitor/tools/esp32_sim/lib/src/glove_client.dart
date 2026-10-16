import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Eldiven ESP32-S3'ü ayrı bir süreç olarak taklit eder: klavyeden okunan
/// tuşları `glove_cmd` olarak robota gönderir (gerçekte ESP-NOW).
class GloveClient {
  GloveClient(this.url);

  static const keys = {'w': 'forward', 's': 'backward', 'a': 'left', 'd': 'right', ' ': 'stop'};

  final Uri url;
  int _seq = 0;

  static String? commandForKey(String key) => keys[key.toLowerCase()];

  String encode(String cmd) => jsonEncode({'type': 'glove_cmd', 'cmd': cmd, 'seq': ++_seq});

  Future<int> run() async {
    final ws = await WebSocket.connect(url.toString());
    stdout.writeln('Eldiven bağlı: $url  ·  W A S D = yön, boşluk = dur, q = çıkış');
    final interactive = stdin.hasTerminal;
    if (interactive) {
      stdin
        ..echoMode = false
        ..lineMode = false;
    }
    try {
      await for (final bytes in stdin) {
        for (final ch in utf8.decode(bytes).split('')) {
          if (ch == 'q') return 0;
          final cmd = commandForKey(ch);
          if (cmd != null) {
            ws.add(encode(cmd));
            stdout.writeln('→ $cmd');
          }
        }
      }
      return 0;
    } finally {
      if (interactive) {
        stdin
          ..lineMode = true
          ..echoMode = true;
      }
      await ws.close();
    }
  }
}
