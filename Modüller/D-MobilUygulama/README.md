# Modül D — Mobil İzleme ve Değerlendirme Uygulaması

**Sorumlu bölüm:** Bilgisayar Müh.  
**Sorumlu kişiler:** _Hakan & Arda_ (2 kişi)

## Amaç
Telefon uygulamasıyla robotun şarj durumunu ve güncel eğim açısını (IMU) göstermek; telefon kamerasıyla robotun hareketlerini optik olarak tespit edip görevi takip etmek, şartnameye göre otomatik değerlendirmek ve değiştirilemez kriptografik sonuç raporu üretmek.

## Minimum İsterler (Şartname §5.2 & Ö4)

### 1. Bağlantı ve Telemetri (5 Puan)
- [x] Robotla kablosuz bağlantı (Wi-Fi SoftAP `CDTP-ROBOT`, IP `192.168.4.1`)
- [x] Şarj ve eğim açısı bilgisi robottan **1 Hz** sıklıkla alınır, canlı gösterilir
- [x] Uygulama çalışırken bağlantı **2 saniyeden fazla** kopmaz (anlık max gap sayacı denetler)
- [x] **Dürüst Veri İlkesi:** Bağlantı yokken uydurma veri gösterilmez (`--`), robot bağlıyken gerçek telemetri yansıtılır

### 2. Optik Takip & Kamera HUD (5 Puan)
- [x] Telefon, robotun hareket alanını görecek şekilde sabit konumlanır (~1.2 m yükseklikte açılı görünüm)
- [x] **ArUco Takibi:** Robotun tepe plakasına yapıştırılan **ArUco DICT_4X4_50 (ID: 0)** optik olarak izlenir
- [x] Canlı HUD: Sayaç, şarj/pil, eğim açısı, kat edilen mesafe ve sol kenarda yön oku (**İLERİ / GERİ / SAĞA / SOLA / DURUYOR**)
- [x] **4 Kesin Hareket Durumu:** `hareket ediyor`, `dönüyor`, `statik denge`, `toparlanma` canlı şeritte bildirilir
- [x] **Kamera Erişimi:** Mobil tarayıcılarda donanımsal arka kameraya güvenli erişim için **HTTPS (Port 8443)** ve akıllı fallback desteği

### 3. Göreve Göre Otomatik Değerlendirme (5 Puan)
- [x] Arayüzden görev seçilir ve göreve özel kriterler denetlenir:
  - **Statik Denge (A):** 30 sn dik dengede kalma (±10° toparlanma)
  - **Robot Yönlendirmesi (B):** Doğru yön + kat edilen mesafe **0.8–1.2 m aralığı**
  - **Şarj Etme (C):** Şarj başlangıcının **en geç 5 sn içinde** tespiti (kamera + eğim + pil)
  - **Bütünleşik Görev (E):** İlaç kutusunun düşürülmeden taşınması ve dock yerleşimi

### 4. Değiştirilemez Kriptografik Rapor (5 Puan)
- [x] Ölçülen gerçek değerler (süre, mesafe, yön, bağlantı boşluğu) otomatik olarak değerlendirilir
- [x] Sonuç raporu **Web Crypto API (SHA-256)** ile hash zincirine işlenir; sonradan elle değiştirilemez

---

## Tasarım Kararları

| Konu | Karar | Not |
| --- | --- | --- |
| **Görsel Tasarım & Renk Teorisi** | Açık Medikal Mühendislik Teması (`#f8fafc`, `#ffffff`, `#1d4ed8`) | 60-30-10 kuralı; neon parlama ve aşırı blur yok, profesyonel klinik okunabilirlik |
| **Navigasyon** | Üstte `← Geri` ve `Menü ☰` çekmecesi; altta adım adım `İleri / Geri` butonları | Kolay ve kontrollü tek elle mobil kullanım |
| **Robot ↔ Telefon İletişimi** | ESP32-S3 Wi-Fi SoftAP, WebSocket JSON (1 Hz) | `ws://192.168.4.1:80/ws` |
| **Görüntü İşleme Yöntemi** | Robot üstünde ArUco (DICT_4X4 ID: 0) tespiti | Işıktan etkilenmez; robot oryantasyonunu ve (x, y) konumunu verir |
| **Mesafe Ölçeği** | 1 metrelik referans işareti (P1–P2 kalibrasyonu) | Piksel → Metre doğrusal dönüşümü |
| **Kamera Güvenliği** | OpenSSL kendinden imzalı yerel sertifika (HTTPS: 8443) | Mobil Chrome/Safari kısıtlamasını aşmak için Secure Context |
| **Değiştirilemez Kayıt** | SHA-256 hash zinciri (`ReportChain`) | Değiştirilemez kriptografik mühür |

---

## Diğer Modüllere Arayüz Sözleşmesi

- **← Robot ESP32 (Modül A + C):** 1 Hz JSON telemetri paketi
  - `tilt_deg`: Robot üzerindeki IMU'dan okunan pitch açısı (Zorunlu - Şartname §5.2)
  - `battery_pct`: Pil doluluk oranı % (Zorunlu)
  - `charging`: Donanımsal `CHG/STAT` şarj sinyali (Zorunlu)
  - `state` & `last_cmd`: Robot hareket modu ve eldivenden gelen son komut
  - `box_present`: İlaç kutusunun robot üstünde olup olmadığı
- **← Kamera Optik Takip (Mobil Sensör):**
  - Robot ArUco etiketi (ID: 0) ile anlık (x, y) ve yön açısı (θ)
  - Kat edilen mesafe (0.8–1.2 m kuralı kamerayla doğrulanır)
  - Yön sınıflandırması (İleri / Geri / Sağa / Sola / Duruyor) kameradan yapılır

---

## Klasör Yapısı

```
Modüller/D-MobilUygulama/
├── README.md               # Bu belge
├── web_app/                # Canlı çalışan profesyonel mobil web arayüzü
│   └── index.html          # Açık temalı, ArUco takipli, canlı WebSocket'li uygulama
├── tools/                  # Geliştirme ve sunucu araçları
│   ├── preview_server.js   # HTTP (8080) & HTTPS (8443) yerel sunucu
│   ├── certs/              # SSL sertifikaları (key.pem, cert.pem)
│   └── esp32_sim/          # ESP32 robot ve eldiven simülatörü
├── vision/
│   └── markers/            # Yazdırılabilir ArUco etiketleri
│       └── aruco_markers.html  # 60x60mm cetvelli ArUco ID 0 & 1 çıktı sayfası
├── app/
│   ├── cdtp_monitor/       # Wireframe uyumlu Flutter projesi
│   └── cdtp_app/           # İlk referans Flutter projesi
└── docs/
    └── wireframes/         # Ekran tel kafes çizimleri ve mimari belgeler
```
