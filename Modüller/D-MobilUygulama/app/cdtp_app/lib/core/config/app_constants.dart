/// Uygulama genelinde kullanilan sabitler.
///
/// Sartnameden gelen degerler (1 Hz, 2 s kopma) burada toplanir; degerlendirme
/// esikleri ise kullanici tarafindan Ayarlar'dan degistirilebilir (bkz. AppSettings).
class AppConstants {
  AppConstants._();

  static const appName = 'ÇDTP Robot İzleme';
  static const appVersion = '0.1.0';

  /// Robot ile uygulama arasindaki mesaj protokolunun surumu (docs/PROTOCOL.md).
  static const protocolVersion = 1;

  /// Sartname 5.2: sarj ve egim bilgisi 1 Hz ile alinir.
  static const expectedTelemetryHz = 1.0;

  /// Sartname 5.2: baglanti 2 s'den fazla kopmamali.
  static const maxLinkGap = Duration(seconds: 2);

  /// Uygulamanin robota ping gonderme araligi (gidis-donus suresi olcumu).
  static const pingInterval = Duration(seconds: 1);

  /// Baglanti koptugunda yeniden deneme araligi.
  static const reconnectDelay = Duration(milliseconds: 500);

  /// Baglanti izleme (watchdog) kontrol periyodu.
  static const watchdogPeriod = Duration(milliseconds: 250);

  /// Panelde grafik icin tutulan son telemetri ornegi sayisi (1 Hz -> 2 dakika).
  static const telemetryHistoryLength = 120;

  /// Baglanti sayfasinda gosterilen olay gunlugu uzunlugu.
  static const eventLogLength = 60;

  /// Hash zincirinin ilk kaydindan onceki "onceki hash" degeri.
  static const genesisHash =
      '0000000000000000000000000000000000000000000000000000000000000000';
}
