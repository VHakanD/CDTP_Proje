# Modül E — İlaç Kutusu Taşıma

**Sorumlu bölüm:** Ortak (yük taşıyıcı mekanik: Kontrol ve Otomasyon; bütünleşik görev: tüm ekip)
**Sorumlu kişiler:** _isim ekle_

## Amaç
Standart ilaç (aspirin vb.) kutusunun görev boyunca robot üzerinde güvenli biçimde taşınması ve hedef noktaya ulaştırılması.

## Minimum isterler (şartname)
- [ ] Kutu kapalı, kuru, kırılmaz, dökülmez biçimde taşınır
- [ ] Görev boyunca robot üzerinde sabit kalır, ancak **gövdeye monte edilmez**
- [ ] Kutu düşerse ilgili alt test başarısız
- [ ] Kutunun marka / içerik / tıbbi özelliği puanlanmaz

## Bütünleşik görev akışı
1. Kutuyla başlar, 5 s dengede bekler
2. Eldiven komutlarıyla ≈ 1 m gider, yön değiştirir
3. Kutuyu düşürmeden hedefte 5 s bekler
4. Şarj istasyonunun yaklaşma bölgesine gelir
5. İstasyonu otonom bulur, hizalanır, dock'a yerleşir
6. Şarj kendiliğinden başlar
7. Mobil uygulama test kaydını ve geçti/kaldı sonucunu üretir

## Değerlendirme (Ö5 — 20 puan)
Aynı bütünleşik görev 4 bağımsız kez; her eksiksiz tam görev 5 puan.

## Tasarım kararları
| Konu | Karar | Not |
| --- | --- | --- |
| Yük taşıyıcı tasarımı | | |
| Kutu konumu (ağırlık merkezi) | | Modül A dengesini etkiler |

## Klasör yapısı
```
E-IlacKutusuTasima/
├── README.md
├── parts/        # parça listesi (parca-listesi.md)
├── mekanik/      # taşıyıcı çizimleri, 3B modeller
└── testler/      # bütünleşik görev deneme kayıtları
```
