# Modül D · Mobil Uygulama Ekran Wireframe'leri

YTÜ ÇDTP "İki Tekerlekli Ev İçi Hasta Destek Robotu" projesinin Modül D'si (robotu
izleyen ve değerlendiren akıllı telefon uygulaması) için ASCII wireframe'ler.

- Çerçeveden (framework) bağımsızdır; Flutter, Kotlin veya başka bir araçla uygulanabilir.
- Renk, tema, yazı tipi ve kütüphane kararı **verilmemiştir**.
- Robot–telefon bağlantı türü (BLE / Wi-Fi) belli olmadığı için yalnızca "bağlantı" denir.
- Kaynak: [Modül D README](../../README.md) (şartname §5.2 özeti).

## Ekranlar arası akış
```text
            ┌──────────────────────────┐  Raporlar
            │ 1 · Bağlantı             │────────────────────┐
            └──────────────────────────┘                    │
                         │                                  │
                         │  bağlandı + doğrulandı           │
                         ▼                                  ▼
            ┌──────────────────────────┐        ┌──────────────────────┐
            │ 2 · Ana Panel            │───────►│ 7a · Rapor Geçmişi   │
            │     (canlı sensör)       │Raporlar└──────────────────────┘
            └──────────────────────────┘                    │
                         │                                  │  satıra dokun
                         │  Görev Seç                       │
                         ▼                                  ▼
Yeni Test   ┌──────────────────────────┐        ┌──────────────────────┐
  ┌────────►│ 3 · Görev Seçimi         │        │ 7b · Rapor Detayı    │
  │         └──────────────────────────┘        │      (kilitli kayıt) │
  │                      │                      └──────────────────────┘
  │                      │  Devam                           ▲
  │                      ▼                                  │
  │         ┌──────────────────────────┐                    │
  │         │ 4 · Kalibrasyon /        │                    │
  │         │     Sahne Hazırlama      │                    │
  │         └──────────────────────────┘                    │
  │                      │                                  │
  │                      │  Hazır                           │
  │                      ▼                                  │
  │         ┌──────────────────────────┐                    │
  │         │ 5 · Kamera + HUD         │                    │
  │         │     Testi Başlat → test  │                    │
  │         └──────────────────────────┘                    │
  │                      │                                  │
  │                      │  Testi Bitir / otomatik bitiş    │
  │                      ▼                                  │
  │         ┌──────────────────────────┐  Raporu Aç         │
  │         │ 6 · Sonuç                │────────────────────┘
  └─────────│     GEÇTİ/KALDI (kilitli)│
            └──────────────────────────┘
            6'dan "Ana Panel" → 2
```

Akışta gösterilmeyen genel geçişler:
- **02–05 arası her ekranda** bağlantı 2 s'den fazla koparsa uyarı çıkar. Yeniden
  bağlanılamazsa kullanıcı **1 · Bağlantı** ekranına döner. Test sürerken (05) kopma
  testi durdurmaz, rapora yazılır.
- Her ekranın geri oku bir önceki ekrana döner. 05'te test sürerken geri tuşu iptal onayı ister.
- 06'dan 05'e geri dönülemez (test bitmiştir).

## Ekran dizini
| # | Ekran | Dosya | Kısa açıklama |
| --- | --- | --- | --- |
| 1 | Bağlantı | [01-baglanti.md](01-baglanti.md) | Robotu bul, bağlan, ilk telemetri paketiyle doğrula |
| 2 | Ana Panel / Canlı Sensör | [02-ana-panel.md](02-ana-panel.md) | Şarj, pil %, eğim (gösterge + 60 s grafik), bağlantı sağlığı |
| 3 | Görev Seçimi | [03-gorev-secimi.md](03-gorev-secimi.md) | 4 görev, başarı metrikleri, B için beklenen yön |
| 4 | Kalibrasyon / Sahne Hazırlama | [04-kalibrasyon-sahne.md](04-kalibrasyon-sahne.md) | Telefon sabit, piksel→metre ölçeği, robot kadrajda, hedef bölge |
| 5 | Kamera + HUD | [05-kamera-hud.md](05-kamera-hud.md) | Canlı test; 2 HUD varyantı × dikey/yatay; yön, canlı mesafe, takip güveni, takip kutusu + ikincil iz |
| 6 | Sonuç | [06-sonuc.md](06-sonuc.md) | GEÇTİ/KALDI, ölçüt bazında sonuç, kilit + doğrulama özeti |
| 7 | Rapor Geçmişi + Detay | [07-rapor-gecmisi-ve-detay.md](07-rapor-gecmisi-ve-detay.md) | Kilitli kayıt listesi, video, olay kaydı, bütünlük doğrulama, dışa aktarma |

## Ortak gösterimler
| Gösterim | Anlamı |
| --- | --- |
| `[1]`, `[2]` … | Ekranın "Öğeler" bölümündeki numaralı açıklama |
| `┌──┐` içinde büyük harf metin | Düğme |
| `[ Metin ]` | İkincil düğme / bağlantı |
| `[x]` / `[ ]` | Tamamlanmış / bekleyen adım |
| `● Bağlı` / `◐ Gecikme` / `○ Koptu` | Bağlantı rozeti (son paketten bu yana ≤1,5 s / 1,5–2 s / >2 s) |
| `▲ ▼ ◀ ▶` | Yön göstergesi (ileri / geri / sol / sağ) |
| `Robot görünüyor %92` | Takip güveni (05) |
| `[KİLİTLİ]` | Mühürlenmiş, düzenlenemez kayıt |
| `✓` / `✕` | Ölçüt geçti / kaldı |

## Varsayımlar ve açık sorular
Bkz. her ekran dosyasının "Durumlar" bölümü. Ekip kararı gerektirenler:

1. **Bağlantı rozeti eşikleri:** `● ≤ 1,5 s`, `◐ 1,5–2 s`, `○ > 2 s` önerildi (1 Hz veri için).
2. **Otomatik bitiş koşulları** (03'teki tablo) varsayımdır: ör. B için "robot belirli
   süre durağan kalınca", A için "30 s dolunca ya da denge bozulunca". Süreler ve eşikler belirlenmeli.
3. **"Süre ±2 s" ölçütünün yorumu:** A'da 30 s hedefine ±2 s tolerans mı (≥ 28 s geçer),
   yoksa ölçülen sürenin doğruluğu mu? Wireframe'de "hedef: 30 s (±2 s)" olarak yazıldı.
4. **"Doğru yön" referansı:** Uygulama beklenen yönü bilmeli. Görev B'de kullanıcının seçtiği
   varsayıldı (03, öğe 3). Alternatif: eldiven komutunun robottan telemetriyle gelmesi.
5. **Yön sınıflandırması kime göre:** Kameraya göre mi, robotun kendi önüne göre mi?
   Kalibrasyonda robotun "önü" tanımlanmalı olabilir.
6. **Hedef bölge (04, adım 4):** C ve E'deki "son konum" ölçütü için kullanıcının şarj
   istasyonu / hedef bölgesini önizlemede çizdiği varsayıldı.
7. **Yük durumu (E):** Kamerayla mı (kutu robotun üzerinde görünüyor mu), robottan gelen
   bir sensörle mi algılanacak? Belirsiz.
8. **Şarj tespiti 5 s (C):** 5 s'nin başlangıç anı (robotun istasyona varışı mı, test başlangıcı mı) belirlenmeli.
9. **Ölçülemeyen ölçüt:** Sonuç KALDI sayıldı (06). Ayrı bir "GEÇERSİZ" kararı istenebilir.
10. **Rapor silme:** "Elle değiştirilemez" kuralı gereği silme düğmesi konmadı. Depolama
    dolarsa ne yapılacağı açık.
11. **Doğrulama özeti:** Örnek olarak SHA-256 gösterildi; yöntem (hash zinciri, imzalı dosya
    vb.) Modül D README'deki tasarım kararlarında seçilecek.
12. **Dışa aktarma biçimi** (PDF, JSON, ZIP vb.) belirlenmedi.
13. **Ölçek isteğe bağlılığı:** Piksel→metre ölçeği yalnızca B için zorunlu tutuldu (mesafe ölçütü).
14. **Canlı mesafe ve takip güveni (ekip kararı):** Şartnamede HUD için istenmese de ikisi de
    05'teki her iki varyanta eklendi. Takip güveni için "düşük" eşiği (ör. %60) ve
    "kayboldu" sayılma süresi belirlenmeli.
