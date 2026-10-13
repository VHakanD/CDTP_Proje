/// Tasima katmaninin (Wi-Fi / BLE) baglanti durumu.
enum TransportState { disconnected, connecting, connected }

/// Robotla konusan kablosuz kanalin soyut arayuzu.
///
/// Uygulamanin geri kalani sadece bu arayuzu bilir; Wi-Fi WebSocket veya
/// BLE UART olmasi fark etmez. Yeni bir yol (orn. seri port) eklemek icin
/// bu sinifi uygulayan yeni bir sinif yazmak yeterlidir.
///
/// Kanal metin satirlari tasir: her mesaj bir JSON nesnesidir.
abstract class RobotLink {
  /// Arayuzde gosterilen hedef (orn. "ws://192.168.4.1:80/ws").
  String get endpoint;

  /// Robottan gelen ham JSON metinleri.
  Stream<String> get messages;

  /// Kanal durumu degisiklikleri.
  Stream<TransportState> get states;

  /// Baglanir. Basarisiz olursa hata firlatir.
  Future<void> connect();

  /// Robota bir JSON metni gonderir. Bagli degilse sessizce yok sayilir.
  void send(String json);

  Future<void> disconnect();

  /// Kaynaklari serbest birakir. Sonrasinda nesne kullanilamaz.
  Future<void> dispose();
}
