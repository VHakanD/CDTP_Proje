# Test Rehberi

Dört seviye vardır. Donanım hazır olmadan ilk üçü tamamen yapılabilir.

| Seviye | Ne gerekir | Neyi test eder |
|---|---|---|
| 1. Docker | Sadece Docker Desktop | Birim testleri, web arayüzü + robot simülatörü |
| 2. Flutter (bilgisayar) | Flutter SDK | Geliştirme döngüsü, Chrome'da çalıştırma |
| 3. Telefon + simülatör | Android telefon, aynı Wi-Fi | Gerçek kamera, video kaydı, SQLite, ağ |
| 4. Telefon + robot | ESP32 robot | Kabul testi provası |

---

## Seviye 1 — Sadece Docker ile

Proje klasöründe:

```powershell
# Birim testleri + statik analiz
docker compose --profile test run --rm tests

# Robot simülatörü + web arayüzü
docker compose up --build
```

İlk derleme Flutter imajını indirdiği için uzun sürer (birkaç GB).

1. Tarayıcıda **http://localhost:8080** (uygulama) ve **http://localhost:8765** (simülatör kontrol paneli) açın.
2. Uygulama → **Bağlantı** → Wi-Fi → **Simülatör localhost:8765/ws** → **Bağlan**.
3. Üst barda **Bağlı · 1,0 Hz** görünmeli.
4. Aşağıdaki senaryo tablosunu uygulayın.

Web sürümünün sınırları: BLE yok, raporlar bellekte (sayfa yenilenince silinir), kamera
tarayıcı izniyle çalışır (localhost'ta izin verilir).

Durdurma: `docker compose down`

## Seviye 2 — Flutter kurulu bilgisayarda

```powershell
.\tool\bootstrap.ps1          # ilk sefer: platform klasörleri, paketler, drift kodu
flutter analyze
flutter test
```

Simülatörü Docker'sız çalıştırmak (Dart SDK Flutter ile gelir):

```powershell
cd tools\robot_simulator
dart run bin\robot_simulator.dart
```

Uygulamayı Chrome'da açmak: `flutter run -d chrome`

## Seviye 3 — Android telefon + bilgisayardaki simülatör

1. Telefonda **Geliştirici seçenekleri > USB hata ayıklama** açık, USB ile bağlayın.
2. `flutter devices` telefonu listelemeli; `flutter run` ile kurun.
   (Kablosuz kurmak için CI'daki `app-debug.apk` dosyasını da kullanabilirsiniz.)
3. Simülatörü bilgisayarda başlatın (Docker veya `dart run`).
4. Bilgisayarın IP'sini bulun: `ipconfig` → Wi-Fi bağdaştırıcısı IPv4 (örn. `192.168.1.34`).
5. Telefon ve bilgisayar **aynı Wi-Fi ağında** olmalı.
6. Windows Güvenlik Duvarı 8765 portuna izin vermeli (ilk çalıştırmada sorulursa "İzin ver";
   gerekirse yönetici PowerShell: `New-NetFirewallRule -DisplayName "CDTP sim" -Direction Inbound -LocalPort 8765 -Protocol TCP -Action Allow`).
7. Uygulama → **Bağlantı** → Adres `192.168.1.34`, Port `8765`, Yol `/ws` → **Bağlan**.
8. Telefondan da kontrol paneli açılabilir: `http://192.168.1.34:8765`.

Bu seviyede ayrıca kontrol edin:
- Test başlatınca kamera önizlemesinde **KAYIT** etiketi.
- Rapor detayında **Video kaydı**: dosya yolu, boyut, SHA-256.
- Uygulamayı kapatıp açınca raporlar duruyor (SQLite), **Kayıtlar**'da "Bütünlük doğrulandı".
- Rapor detayında **JSON dosyası olarak kaydet**.

## Seviye 4 — Gerçek robot (ESP32)

[PROTOCOL.md §5](PROTOCOL.md#5-robota-bağlanma-adımları) adımlarını izleyin
(`CDTP-ROBOT` ağı, mobil veri kapalı, **ESP32 SoftAP** hazır ayarı).

ESP32 tarafı hazır değilse önce robot kodunu doğrulayın: bilgisayarı `CDTP-ROBOT` ağına
bağlayıp tarayıcı konsolunda:

```js
const w = new WebSocket('ws://192.168.4.1/ws'); w.onmessage = e => console.log(e.data);
```

Her saniye bir `telemetry` satırı görülmeli.

---

## Senaryo tablosu (simülatör kontrol paneliyle)

| # | Adım | Beklenen sonuç |
|---|---|---|
| 1 | Bağlan | Bağlantı: **Bağlı**, frekans ≈ 1,00 Hz, olay günlüğü: `Robot: CDTP-ROBOT-SIM` |
| 2 | Panel'i açın | Şarj %, eğim, eğim grafiği her saniye güncellenir |
| 3 | Simülatör: **3 s bağlantı kes** | ~2 s sonra durum kırmızı **Veri gelmiyor**; veri dönünce **Bağlı**; "2 s aşımı" 1 artar |
| 4 | Simülatördeki konteyneri durdurun (`docker compose stop simulator`) | **Bağlantı koptu**, uygulama 0,5 s aralıkla yeniden dener; başlatınca kendiliğinden bağlanır |
| 5 | Test → **Statik Denge** → Testi Başlat, bekleyin | 31. saniyede otomatik biter → **GEÇTİ**; "Yerinde kalma (kamera)" = Veri yok (bilgi) |
| 6 | Statik Denge başlat, 10. s'de **Düş** | Otomatik biter (Düşme tespit edildi) → **KALDI**. Sonra simülatörde **Dengede dur** |
| 7 | Statik Denge sırasında **3 s bağlantı kes** | Sonuç **KALDI**, "Bağlantı sürekliliği: en uzun boşluk ~3–4 s" |
| 8 | Simülatör: **İstasyondan çek**. Test → **Şarj Etme** → Başlat → **İstasyona yerleş** | 3 s sonra yerleşir, 2 s sonra şarj; 2 s sonra otomatik biter → **GEÇTİ** (≈ 2 s) |
| 9 | **Robot Yönlendirmesi** (İleri) → Başlat → **İleri** → Testi Bitir | **EKSİK VERİ** (kamera tespiti yok); "Robotun aldığı komut: İleri" (bilgi) |
| 10 | Simülatör: İstasyondan çek, Kutu yerinde. **Bütünleşik Görev** → Başlat → 6 s bekle → **İleri** → 6 s bekle → **İstasyona yerleş** | Otomatik biter. Başlangıç dengesi, kutu, hedefte bekleme, şarj = Sağlandı; hareket mesafesi = Veri yok → **EKSİK VERİ** |
| 11 | 10'u tekrarlayın, ortada **Kutu düştü** | **KALDI** ("İlaç kutusu taşındı: Kutu düştü") |
| 12 | Kayıtlar | Görev bazında sayılar doğru; üstte **Bütünlük doğrulandı** |
| 13 | Rapor detayı | Kriter tablosu, telemetri satırları (~1 s aralık), hash; düzenleme düğmesi yok |

Kamera tespiti eklendiğinde 9 ve 10 numaralı senaryolar **GEÇTİ** olmalıdır.

## Ö4 (Mobil ölçüm, 20 puan) kontrol listesi

| Alt test | Nasıl gösterilir |
|---|---|
| 1. 1 Hz şarj + eğim, canlı | Panel + Bağlantı sayfasında frekans ≈ 1 Hz, en uzun boşluk < 2 s |
| 2. Kameradan hareket ve yön | Canlı test ekranında Hareket / Yön kutuları (kamera modülü tamamlanınca) |
| 3. Otomatik değerlendirme | Testi Bitir veya otomatik bitiş → GEÇTİ/KALDI kendiliğinden |
| 4. Değiştirilemez rapor | Rapor detayında kilit simgesi, düzenleme yok; Kayıtlar: "Bütünlük doğrulandı"; video SHA-256 |

## Final günü prosedürü

1. Telefon şarjlı, tripodda **sabit**, robotun hareket alanını görecek şekilde.
2. Ayarlar → eşikleri kontrol edin; **test başladıktan sonra değiştirmeyin** (şartname 4.1).
3. Bağlantı → Bağlı · 1 Hz.
4. Robot dengede ve hareketsizken Test → görev → **Testi Başlat**.
5. Bitince sonuç ekranını jüriye gösterin; Kayıtlar → Bütünlük doğrulandı.
6. Ö5 için bütünleşik görevi 4 kez tekrarlayın; Kayıtlar'daki "Bütünleşik Görev" satırında
   geçen sayısı görünür.

## Otomatik testler (kod)

| Dosya | İçerik |
|---|---|
| `test/protocol_codec_test.dart` | JSON mesaj çözme, eksik/bozuk alanlar |
| `test/evaluators_test.dart` | 4 görevin geçti/kaldı/eksik veri kararları (sahte telemetri ve kamera örnekleriyle) |
| `test/report_chain_test.dart` | Hash zinciri, kurcalanmış kaydın tespiti |
| `test/widget_test.dart` | Menü ve sayfaların açılması, ayarların kaydı |
