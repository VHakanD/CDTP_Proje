/// Türkçe sayı ve süre biçimleri (ondalık ayırıcı virgül).
String fmtNum(num v, [int digits = 1]) => v.toStringAsFixed(digits).replaceAll('.', ',');

String fmtSecs(Duration d, [int digits = 1]) => '${fmtNum(d.inMilliseconds / 1000, digits)} s';

/// 00:12,4 biçimi.
String fmtClock(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  final ds = (d.inMilliseconds % 1000) ~/ 100;
  return '$m:$s,$ds';
}

String fmtSigned(double v, [int digits = 1]) => '${v >= 0 ? '+' : ''}${fmtNum(v, digits)}';

String fmtDateTime(DateTime t) {
  String two(int x) => x.toString().padLeft(2, '0');
  return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

String fmtTime(DateTime t) {
  String two(int x) => x.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

String shortHash(String h) => h.length < 12 ? h : '${h.substring(0, 4)}…${h.substring(h.length - 4)}';
