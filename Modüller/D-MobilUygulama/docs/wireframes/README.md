# Modül D · Mobil Uygulama Ekran Wireframe'leri

YTÜ ÇDTP "İki Tekerlekli Ev İçi Hasta Destek Robotu" projesinin Modül D'si (robotu
izleyen ve değerlendiren akıllı telefon uygulaması) için ASCII wireframe'ler.

- Tıklanabilir HTML sürümü: [html/index.html](html/index.html) (tüm ekranlar tek dosyada, durum geçişleri ve notlarla).
- Uygulama: Flutter (Android). Robot ve eldiven tarafında **ESP32-S3, Wi-Fi** kullanılır; telefon robota WebSocket ile bağlanır.
- Kamera ekranı için **Varyant B** seçildi; yön göstergesi sol kenara alındı. Görüntü oranı 1:1 varsayılan, 4:3 ve 9:16 seçilebilir.
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

## Kararlar (Cevaplar.md'ye göre)
Açık soruların yanıtları; kaynak şartname ve tanıtım sunumu.

| # | Konu | Karar |
| --- | --- | --- |
| 1 | Bağlantı rozeti | Şartname yalnız 2 s kopma sınırını zorunlu tutar. Eşikler ekip seçimi: `≤ 1,5 s` bağlı, `1,5–2 s` gecikme, `> 2 s` koptu. |
| 2 | Otomatik bitiş | A: 30 s dolunca ya da denge bozulunca. B: 0,8–1,2 m sonrası robot durunca. C: dock'a yerleşmeden sonra şarj başlayınca ya da 5 s aşılınca. E: hedefte 5 s bekleme + şarj başlangıcı. |
| 3 | Süre ±2 s | Uygulamanın ölçtüğü süre ile hedef süre arasındaki tolerans. A'da 28–32 s penceresi geçerlidir; jüri kronometresi referanstır. |
| 4 | Doğru yön | Görev B'de kullanıcı beklenen yönü seçer; kameradan algılanan yön bununla karşılaştırılır. |
| 5 | Yön referansı | Şartname serbest bırakır. Uygulama kamera görüntüsüne göre sınıflar; robotun önü sahne hazırlamada başlangıç konumuyla tanımlanır. |
| 6 | Hedef bölge | C: 30 cm / 90° yaklaşma bölgesi ve istasyon, E: hedef nokta; ikisi de sahne hazırlamada (04) çizilir. |
| 7 | Yük durumu | Yöntem ekibe bırakılmış. Uygulama kamerayla kutunun robot üzerinde görünüp görünmediğine bakar; robot ileride bir sensör verisi gönderirse o da kullanılır. |
| 8 | Şarj 5 s | 5 s, robotun dock'a oturup motorlarının durduğu anda başlar. |
| 9 | Ölçülemeyen ölçüt | KALDI (0 puan). Ayrı bir "GEÇERSİZ" kategorisi yoktur. |
| 10 | Rapor silme | Silme ve düzenleme yok. Depolama yönetimi mimari kararıdır. |
| 11 | Mühürleme | SHA-256 hash zinciri (her rapor bir öncekinin özetini içerir). |
| 12 | Dışa aktarma | Ekip seçimi: PDF (jüri için) + JSON (makine okunur). |
| 13 | Ölçek | B ve E için zorunlu; 0,8–1,2 m mesafe ölçümü buna dayanır. |
| 14 | Mesafe ve takip güveni | Ekibin eklediği HUD öğeleri. Eşikler: güven < %60 "zor görünüyor", robot 1 s bulunamazsa "kayboldu". |
