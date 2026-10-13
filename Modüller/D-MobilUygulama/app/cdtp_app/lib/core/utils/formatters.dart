/// Ekranda gosterilen sayi ve sure bicimleri.
///
/// Turkce yazimda ondalik ayirac virgul oldugu icin "1,4°" seklinde gosterilir.
/// Deger yoksa (sensor henuz hazir degil) tire "—" gosterilir.
class Fmt {
  Fmt._();

  static const empty = '—';

  static String number(num? value, {int digits = 1, String suffix = ''}) {
    if (value == null) return empty;
    return '${value.toStringAsFixed(digits).replaceAll('.', ',')}$suffix';
  }

  static String percent(num? value) => value == null ? empty : '%${number(value, digits: 0)}';

  static String degrees(num? value) => number(value, digits: 1, suffix: '°');

  static String meters(num? value) => number(value, digits: 2, suffix: ' m');

  static String seconds(num? value) => number(value, digits: 1, suffix: ' s');

  static String boolTr(bool? value, {String yes = 'Evet', String no = 'Hayır'}) {
    if (value == null) return empty;
    return value ? yes : no;
  }

  /// 75 saniye -> "01:15"
  static String clock(Duration d) {
    final m = d.inMinutes.remainder(100).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// 75.3 saniye -> "01:15,3"
  static String clockPrecise(Duration d) {
    final tenths = (d.inMilliseconds.remainder(1000) / 100).floor();
    return '${clock(d)},$tenths';
  }

  static String dateTime(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final l = t.toLocal();
    return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }

  static String time(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final l = t.toLocal();
    return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }

  static String shortHash(String hash) => hash.length > 12 ? '${hash.substring(0, 12)}…' : hash;
}
