# Modül A — Denge Robotu

**Sorumlu bölüm:** Kontrol ve Otomasyon Müh. (+ mekanik/güç tarafında Elektrik Müh. ile ortak)
**Sorumlu kişiler:** _isim ekle_

## Amaç
İki aynı eksenli ana teker üzerinde, haricî destek olmadan aktif denge ve kontrollü hareket.

## Minimum isterler (şartname)
- [ ] Yalnız iki ana teker; üçüncü teker / ayak / zemine değen destek yok
- [ ] Pasif kararlılık ön testi: motorlar enerjisizken ±10°'den bırakılınca 5 s içinde kendiliğinden dik durmamalı
- [ ] 30 s statik denge
- [ ] Yaklaşık 1 m ileri gidip 3 s durma
- [ ] Yaklaşık 1 m geri dönüp 3 s durma
- [ ] +10° ve −10° başlangıç eğiminden 10 s içinde toparlanma (iki yön birlikte)
- [ ] İlaç kutusu yüklüyken de kararlı kalma
- [ ] Şarj istasyonuna kontrollü yaklaşma ve durma (Modül C ile ortak)

## Değerlendirme (Ö1 — 20 puan)
Her alt test geçti = 5 / kaldı = 0.

## Tasarım kararları
| Konu | Karar | Not |
| --- | --- | --- |
| Kontrol yöntemi | _PID / LQR / ..._ | |
| MCU | | |
| IMU | | |
| Motor + sürücü | | |

## Diğer modüllere arayüz
- **→ Modül D:** eğim açısı (°) ve hareket durumu, 1 Hz telemetri
- **← Modül B:** ileri / geri / sol / sağ / dur komutları
- **↔ Modül C:** istasyon yaklaşma modu, yerleşince motorları durdurma

## Klasör yapısı
```
A-DengeRobotu/
├── README.md
├── parts/        # parça listesi (parca-listesi.md)
├── firmware/     # denge döngüsü, motor kontrol kodu
├── simulasyon/   # model, parametre denemeleri
└── docs/         # şemalar, ölçüm sonuçları
```
