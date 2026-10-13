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
| Platform / framework | _Flutter / Kotlin / React Native ..._ | |
| Robot ↔ telefon bağlantısı | _BLE / Wi-Fi ..._ | Robot tarafı firmware ile birlikte |
| Görüntü işleme yöntemi | _OpenCV renk/marker takibi, ML ..._ | |
| Mesafe ölçeği | _zemin marker'ı / bilinen boyut ..._ | |
| Değiştirilemez kayıt | _hash zinciri / imzalı dosya ..._ | |

## Diğer modüllere arayüz
- **← Modül A:** eğim açısı (°), 1 Hz
- **← Modül C:** şarj durumu + pil seviyesi (%), 1 Hz
- Telemetri paket formatı tüm ekiple birlikte belirlenip ana README'deki **Arayüzler** bölümüne yazılmalı.

## Klasör yapısı
```
D-MobilUygulama/
├── README.md
├── parts/        # parça listesi (parca-listesi.md)
├── app/          # mobil uygulama kaynak kodu
├── vision/       # görüntü işleme denemeleri / modeller
└── docs/         # ekran tasarımları, test kayıtları
```
