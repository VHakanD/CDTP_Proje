# Modül C — Otomatik Şarj İstasyonu

**Sorumlu bölüm:** Elektrik Müh. (istasyona yaklaşma kontrolünde Kontrol ve Otomasyon ile ortak)
**Sorumlu kişiler:** _isim ekle_

## Amaç
Robotun şarj istasyonuna insan veya eldiven yönlendirmesi olmadan otonom yerleşmesi ve şarjın otomatik başlaması.

## Minimum isterler (şartname)
- [ ] Robot, istasyon merkezli 30 cm yarıçaplı, 90° yaklaşma bölgesinden başlar
- [ ] Bu noktadan sonra insan / eldiven komutu yok; istasyonu **IR alıcı-verici** ile algılar
- [ ] Yönünü ve hızını ayarlayarak hizalanır, dock'a yerleşir; stabil olunca motorlar durur
- [ ] Doğru yerleşmeden sonra şarj en geç 5 s içinde kendiliğinden başlar
- [ ] Enerji aktarımı: temas pedi / yaylı kontak / endüktif — elle kablo takılmaz
- [ ] Şarj göstergesi şarj devresinin CHG/STAT (donanımsal) sinyaliyle yanar; yazılımla yakılamaz
- [ ] Robot çekilince gösterge en geç 2 s içinde söner, geri gelince en geç 5 s içinde yanar
- [ ] Güvenlik: ana besleme ≤ 24 V DC, BMS'li lityum paket, motor hattında sigorta, erişilebilir acil durdurma

## Değerlendirme (Ö3 — 20 puan)
Algılama · otonom yerleşme · 5 s içinde şarj + gösterge · çekince söner/dönünce yanar — her biri 5 puan.

## Tasarım kararları
| Konu | Karar | Not |
| --- | --- | --- |
| Batarya / BMS | | |
| Şarj entegresi (CHG/STAT çıkışlı) | | |
| Robot–istasyon temas yöntemi | | |
| IR verici/alıcı düzeni | | |

## Diğer modüllere arayüz
- **→ Modül D:** şarj durumu (şarj oluyor / olmuyor) ve pil seviyesi (%), 1 Hz telemetri
- **↔ Modül A:** otonom yaklaşma modu

## Klasör yapısı
```
C-SarjIstasyonu/
├── README.md
├── parts/        # parça listesi (parca-listesi.md)
├── donanim/      # güç şeması, PCB
├── firmware/     # IR yaklaşma / hizalama kodu
└── docs/
```
