# ÇDTP Robot İzleme Uygulaması

YTÜ EEF Çok Disiplinli Tasarım Projesi 2026-2027 Güz — **İki Tekerlekli Ev İçi Hasta Destek Robotu**
için mobil izleme ve değerlendirme uygulaması (**Modül D**, puan tablosu **Ö4**).

Uygulama robotla kablosuz bağlanır, şarj ve eğim bilgisini 1 Hz ile gösterir, telefon
kamerasıyla testi kaydeder, seçilen görevi otomatik olarak **GEÇTİ / KALDI** diye
değerlendirir ve sonucu değiştirilemez biçimde saklar.

- Flutter + Riverpod, Android birincil (web sürümü arayüz testi için)
- Robot bağlantısı: ESP32 **Wi-Fi WebSocket** (birincil), **Bluetooth LE UART** (ikincil)
- Depolama: **SQLite (drift)**, UPDATE/DELETE engelli + SHA-256 hash zinciri
- Robot simülatörü ve Docker ile donanımsız test

## Modüller

| Menü | İçerik |
|---|---|
| Panel | Canlı telemetri: şarj, eğim, şarj durumu, istasyon, robot durumu, kutu, eldiven komutu, grafikler |
| Test | Statik Denge (A), Robot Yönlendirmesi (B), Şarj Etme (C), Bütünleşik Görev (E) |
| Kayıtlar | Raporlar, görev bazında özet, bütünlük doğrulama, rapor detayı, JSON dışa aktarma |
| Bağlantı | Wi-Fi/BLE seçimi, adres, bağlantı kalitesi (Hz, kopma, RTT), olay günlüğü |
| Ayarlar | Tema, video kaydı, değerlendirme eşikleri, veri bütünlüğü |

## Durum

| Bölüm | Durum |
|---|---|
| Ağ modülü (WebSocket, watchdog, yeniden bağlanma, istatistik) | Hazır — robot tarafı [PROTOCOL.md](docs/PROTOCOL.md)'ye göre yazılacak |
| BLE bağlantısı | Kod hazır — gerçek ESP32 ile denenmeli |
| Telemetri paneli | Hazır |
| Test akışı, otomatik bitiş, değerlendirme | Hazır |
| Değiştirilemez rapor (SQLite + hash zinciri + video SHA-256) | Hazır |
| Kamera önizleme ve video kaydı | Hazır |
| **Kameradan hareket / yön / mesafe tespiti** | **Boş arayüz** — yöntem ekipçe seçilecek ([ARCHITECTURE.md §6](docs/ARCHITECTURE.md#6-kamera-modülü-planı)) |
| Kamera kalibrasyonu | Yer tutucu |
| PDF rapor | Planlandı (JSON dışa aktarma hazır) |

## Hızlı başlangıç

### Flutter kurulu bilgisayarda

```powershell
git clone <repo-adresi>
cd cdtp_app
.\tool\bootstrap.ps1        # Linux/macOS: sh tool/bootstrap.sh
flutter test
flutter run                 # bağlı Android telefonda
```

`bootstrap` betiği eksik platform klasörlerini (`android/`, `web/`) oluşturur — mevcut
`lib/`, `AndroidManifest.xml` gibi dosyalara dokunmaz — paketleri indirir ve drift
veritabanı kodunu üretir (`lib/data/db/app_database.g.dart`). Oluşan `android/` ve `web/`
klasörlerini ve `.g.dart` dosyasını depoya ekleyin.

Veritabanı tablosu değişirse: `dart run build_runner build --delete-conflicting-outputs`

### Sadece Docker ile

```powershell
docker compose --profile test run --rm tests   # analiz + birim testleri
docker compose up --build                      # simülatör + web arayüzü
```

- Uygulama: http://localhost:8080
- Simülatör kontrol paneli: http://localhost:8765
- Uygulamada: Bağlantı → **Simülatör localhost:8765/ws** → Bağlan

Ayrıntılı test adımları ve senaryolar: [docs/TESTING.md](docs/TESTING.md)

## Robota bağlanma (özet)

1. Robot `CDTP-ROBOT` Wi-Fi ağını açar (ESP32 SoftAP, `192.168.4.1`).
2. Telefon bu ağa bağlanır, mobil veri kapatılır.
3. Uygulama → Bağlantı → **ESP32 SoftAP** → Bağlan.

Mesaj formatı, alanlar, BLE UUID'leri ve sorun giderme: [docs/PROTOCOL.md](docs/PROTOCOL.md).
ESP32 için örnek kod: [docs/esp32_reference/robot_link/robot_link.ino](docs/esp32_reference/robot_link/robot_link.ino).

## Klasör yapısı

```
lib/
  app/            Kök widget, menü, tema
  core/           Sabitler, biçimlendirme, hash, ortak widget'lar
  data/db/        drift (SQLite) tablosu
  features/
    connection/   Ağ modülü (WiFi WebSocket, BLE, protokol, bağlantı yöneticisi)
    dashboard/    Canlı telemetri paneli
    camera/       Kamera, video kaydı, hareket tespit arayüzü
    tasks/        Görevler, test oturumu, otomatik değerlendirme
    reports/      Değiştirilemez raporlar, hash zinciri
    settings/     Ayarlar ve eşikler
test/             Birim ve widget testleri
tools/robot_simulator/   ESP32 yerine geçen WebSocket simülatörü (Dart)
docs/             Mimari, protokol, test rehberi, ESP32 referans kodu
```

Mimari ayrıntıları ve arayüz planı: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Gereksinimler

- Flutter 3.27 veya üstü (stable), Dart 3.6+
- Android 5.0+ (API 21+), kamera ve Wi-Fi
- Docker Desktop (opsiyonel, test ortamı için)
