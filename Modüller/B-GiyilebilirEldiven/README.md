# Modül B — Giyilebilir Komut Arayüzü (Eldiven)

**Sorumlu bölüm:** Elektronik ve Haberleşme Müh.
**Sorumlu kişiler:** _isim ekle_

> ⚠️ Ekipte Biyomedikal Müh. yok. Şartnamede Biyomedikal'e önerilen işler (IMU/EMG seçimi ve yerleşimi, kullanıcı kalibrasyonu, sinyal işleme, beş komuta dönüştürme, ergonomi) bu modülün ekibine ya da başka bir kişiye **atanmalı**.

## Amaç
Eldiven üzerindeki IMU, EMG veya eşdeğer insan girdisinden ileri / geri / sağ / sol / dur komutlarının kablosuz üretilmesi.

## Minimum isterler (şartname)
- [ ] El/kol hareketi veya kas aktivitesinden 5 ayrı komut: ileri, geri, sola dön, sağa dön, dur
- [ ] Komutlar kablosuz gider; gövde düğmesi veya telefondan manuel komut kabul edilmez
- [ ] Robot 2 s içinde tepki verir ve dengesini korur
- [ ] İleri/geri ≈ 0,5 m; dönüş ≈ 90°; her hareketten sonra "dur"
- [ ] Kalibrasyon serbest; final testi başladıktan sonra eşik/algoritma değişmez
- [ ] Biyosinyal ölçülecekse yalnız bataryalı, şebekeden galvanik olarak yalıtılmış düzenek

## Değerlendirme (Ö2 — 20 puan)
İleri, geri, sola, sağa: her başarılı komut 5 puan. "Dur" bunlarla birlikte değerlendirilir.

## Tasarım kararları
| Konu | Karar | Not |
| --- | --- | --- |
| Sensör (IMU / EMG) | | |
| Eldiven MCU | | |
| Kablosuz bağlantı | _BLE / ESP-NOW / nRF24 ..._ | Robot tarafı alıcı ile ortak |
| Jest → komut eşlemesi | | |

## Diğer modüllere arayüz
- **→ Modül A:** komut paketi (ileri / geri / sol / sağ / dur)

## Klasör yapısı
```
B-GiyilebilirEldiven/
├── README.md
├── parts/        # parça listesi (parca-listesi.md)
├── firmware/     # eldiven MCU kodu
├── alici/        # robot tarafı alıcı kodu
└── docs/         # devre şeması, kalibrasyon notları
```
