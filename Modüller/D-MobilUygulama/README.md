# Modül D — Mobil İzleme ve Değerlendirme Uygulaması

**Sorumlu bölüm:** Bilgisayar Müh.
**Sorumlu kişiler:** _Hakan&Arda_ (2 kişi)

## Amaç
Telefon uygulamasıyla robotun şarj durumunu ve güncel eğim açısını göstermek; telefon kamerasıyla robotun hareketlerini tespit edip görevi takip etmek, otomatik değerlendirmek ve raporlamak.

## Minimum isterler (şartname §5.2)
**Bağlantı ve telemetri**
- [ ] Robotla kablosuz bağlantı; bağlantının kurulduğu arayüzde doğrulanır
- [ ] Şarj ve eğim açısı bilgisi robottan **1 Hz** alınır, canlı gösterilir
- [ ] Uygulama çalışırken bağlantı **2 s'den fazla** kopmaz

**Test akışı**
- [ ] Telefon, robotun hareket alanını görecek şekilde sabit konumlanır
- [ ] Arayüzden görev seçilir: Statik Denge (A) · Robot Yönlendirmesi (B) · Şarj Etme (C) · Bütünleşik Görev (E)
- [ ] "Testi Başlat" → başlangıç zaman damgası + kamera kaydı başlar
- [ ] Canlı: sayaç, şarj, eğim, hareket durumu (hareket ediyor / dönüyor / statik denge / toparlanma) ve yön (ileri / geri / sağ / sol)
- [ ] "Testi Bitir" veya önceden tanımlı bitiş koşulunun otomatik tespiti

**Değerlendirme ve rapor**
- [ ] Süre (±2 s), mesafe (0,8–1,2 m), hareket yönü, son konum, yükün durumu ile otomatik geçti/kaldı
- [ ] Sonuç: video veya zaman damgalı kayıt + ölçülen değerler + geçti/kaldı
- [ ] Rapor sonradan **elle değiştirilemez** biçimde saklanır

### Görev başarı metrikleri
| Görev | Modül | Başarı metriği |
| --- | --- | --- |
| Statik Denge | A | 30 s dengede kalmak |
| Robot Yönlendirmesi | B | Doğru yön + kat edilen mesafe 0,8–1,2 m |
| Şarj Etme | C | Şarj başlangıcının 5 s içinde tespiti (kamera + eğim + pil düzeyi) |
| Bütünleşik Görev | E | İlaç kutusunun başarıyla taşınması |

## Değerlendirme (Ö4 — 20 puan)
1. 1 Hz şarj + eğim verisi canlı · 2. Kameradan hareket/yön tespiti · 3. Seçilen göreve göre otomatik değerlendirme · 4. Değiştirilemez otomatik rapor — her biri 5 puan.

## Önerilen alt bölümler
| Alt bölüm | İçerik |
| --- | --- |
| Uygulama + iletişim | Bağlantı, 1 Hz telemetri, arayüz, görev seçimi, sayaç, rapor saklama |
| Görüntü işleme | Robot tespiti/takibi, hareket ve yön sınıflandırma, piksel → metre ölçek kalibrasyonu, mesafe ölçümü |

## Tasarım kararları
| Konu | Karar | Not |
| --- | --- | --- |
| Platform / framework | Flutter (Android) · go_router · MVVM | `app/cdtp_monitor` |
| Robot ↔ telefon bağlantısı | ESP32-S3 Wi-Fi, WebSocket JSON (protokol v1) | Eldiven ↔ robot: ESP-NOW önerisi |
| Görüntü işleme yöntemi | Robot üstünde macenta renk işareti, telefonda YUV eşik + ağırlık merkezi | Robot olmadan: simülatör sahnesi |
| Mesafe ölçeği | Zemindeki 1 m işaretin iki ucuna dokunma (P1–P2) | Sahne hazırlama ekranı |
| Değiştirilemez kayıt | SHA-256 hash zinciri, yalnız ekleme | Dışa aktarma: JSON |
| Kamera görünümü | HUD Varyant B, yön göstergesi sol kenarda; 1:1 varsayılan, 4:3 ve 9:16 seçilebilir | `docs/wireframes/html/` |

## Diğer modüllere arayüz
- **← Modül A:** eğim açısı (°), 1 Hz
- **← Modül C:** şarj durumu + pil seviyesi (%), 1 Hz
- Telemetri paket formatı tüm ekiple birlikte belirlenip ana README'deki **Arayüzler** bölümüne yazılmalı.

## Klasör yapısı
```
D-MobilUygulama/
├── README.md
├── parts/        # parça listesi (parca-listesi.md)
├── app/
│   ├── cdtp_app/      # ilk altyapı (wireframe'den bağımsız)
│   └── cdtp_monitor/  # wireframe uyumlu uygulama + ESP32-S3 simülatörü + Docker
├── vision/       # görüntü işleme denemeleri / modeller
└── docs/
    └── wireframes/    # ekran wireframe'leri (.md) + html/index.html
```
