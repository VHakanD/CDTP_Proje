# 07 · Rapor Geçmişi ve Rapor Detayı

[← Ekran dizini](README.md) · Önceki: [06 · Sonuç](06-sonuc.md)

## 07a · Rapor Geçmişi

### Amaç
Bu cihazda yapılmış tüm testlerin kilitli raporlarını tarih sırasıyla listelemek.

### Wireframe
```text
┌──────────────────────────────────────┐
│ ← Rapor Geçmişi                  [1] │
├──────────────────────────────────────┤
│ 12 rapor · en yeni üstte             │
│  ┌────────────────────────────────┐  │
│  │ 13.10.2026 14:40               │  │
│  │ A · Statik Denge               │  │
│  │ KALDI                          │  │
│  │ [KİLİTLİ] c07e…f80c            │  │
│  ├────────────────────────────────┤  │
│  │ 13.10.2026 14:32               │  │
│  │ B · Robot Yönlendirmesi        │  │
│  │ GEÇTİ                          │  │
│  │ [KİLİTLİ] 3f9a…b41d            │  │
│  ├────────────────────────────────┤  │
│  │ 12.10.2026 16:05               │  │
│  │ C · Şarj Etme                  │  │
│  │ GEÇTİ                          │  │
│  │ [KİLİTLİ] 8b11…02aa            │  │
│  ├────────────────────────────────┤  │
│  │ 12.10.2026 15:47               │  │
│  │ E · Bütünleşik Görev           │  │
│  │ TEST KESİLDİ                   │  │
│  │ [KİLİTLİ] 41fe…9c3d            │  │
│  ├────────────────────────────────┤  │
│  │ …                              │  │
│  └────────────────────────────────┘  │
│     [2] tarih  [3] görev             │
│     [4] karar  [5] kilit + kısa özet │
└──────────────────────────────────────┘
```

### Öğeler
1. **Başlık ve geri oku:** Geldiği ekrana (01, 02 ya da 06) döner.
2. **Tarih ve saat:** Testin başlangıç zaman damgası.
3. **Görev:** Modül harfi ve görev adı.
4. **Karar:** `GEÇTİ` / `KALDI` / `TEST KESİLDİ`.
5. **Kilit rozeti ve kısa doğrulama özeti:** Her kaydın mühürlü olduğunu gösterir.
   Satıra dokununca 07b açılır.

Listede düzenleme ya da silme işlemi yoktur.

### Durumlar
**Boş liste**
```text
┌──────────────────────────────────────┐
│ ← Rapor Geçmişi                      │
├──────────────────────────────────────┤
│                                      │
│                                      │
│                                      │
│           Henüz rapor yok.           │
│                                      │
│       Bir test tamamlandığında       │
│        raporu burada görünür.        │
│                                      │
│                                      │
└──────────────────────────────────────┘
```

| Durum | Davranış |
| --- | --- |
| Boş | "Henüz rapor yok" mesajı. |
| Yükleniyor | Liste yerine bekleme göstergesi. |
| Bütünlüğü bozuk kayıt | Satırda `[KİLİTLİ]` yerine `! doğrulanamadı` gösterilir. |

---

## 07b · Rapor Detayı

### Amaç
Tek bir testin kilitli raporunu göstermek: video/zaman damgalı kayıt, ölçülen değerler,
karar ve doğrulama özeti. Kayıt salt okunurdur; **düzenle düğmesi yoktur**. Kullanıcı
yalnızca izleyebilir, bütünlüğü doğrulayabilir ve dışa aktarabilir.

### Wireframe
```text
┌──────────────────────────────────────┐
│ ← Rapor · 13.10.2026 14:32       [6] │
│ [KİLİTLİ] Değiştirilemez kayıt   [7] │
├──────────────────────────────────────┤
│ Görev B · Robot Yönlendirmesi        │
│ 14:32:05 → 14:32:19 · 14,2 s         │
│ Karar: GEÇTİ (3/3)               [8] │
│ VİDEO                            [9] │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  │              ▶                 │  │
│  │                                │  │
│  │ 00:05 ━━━━━●───────────── 00:14│  │
│  │       ▲     ▲          ▲       │  │
│  │       olay işaretleri          │  │
│  └────────────────────────────────┘  │
│ ÖLÇÜLEN DEĞERLER                [10] │
│  ┌────────────────────────────────┐  │
│  │ Yön        İleri    ✓          │  │
│  │ Mesafe     0,97 m   ✓          │  │
│  │ Son konum  durdu    ✓          │  │
│  │ Süre       14,2 s   bilgi      │  │
│  └────────────────────────────────┘  │
│ OLAY KAYDI (zaman damgalı)      [11] │
│  ┌────────────────────────────────┐  │
│  │ 00:00,0  Test başladı          │  │
│  │ 00:01,3  hareket ediyor · İLERİ│  │
│  │ 00:13,1  statik denge          │  │
│  │ 00:14,2  Bitiş: robot durdu    │  │
│  │ Telemetri: 15 paket, 0 kopma   │  │
│  └────────────────────────────────┘  │
│ TEST KOŞULLARI                  [12] │
│   Ölçek 412 px/m · beklenen yön İleri│
│ DOĞRULAMA                       [13] │
│   SHA-256:                           │
│   3f9a7c2e5d10a8e4…c6f291d0b41d      │
│   Mühürlenme: 13.10.2026 14:32:20    │
│   [ Bütünlüğü doğrula ]  ✓ değişmemiş│
│                                      │
│  ┌────────────────────────────┐      │
│  │         DIŞA AKTAR         │ [14] │
│  └────────────────────────────┘      │
└──────────────────────────────────────┘
```

### Öğeler
6. **Başlık:** Raporun tarih/saati. Geri oku 07a'ya (ya da 06'ya) döner.
7. **Kilit rozeti:** `[KİLİTLİ] Değiştirilemez kayıt`. Ekranda hiçbir alan düzenlenemez.
8. **Karar:** GEÇTİ / KALDI ve sağlanan ölçüt sayısı.
9. **Video oynatıcı:** Oynat/duraklat, zaman çubuğu. Çubuk üzerindeki işaretler olay kaydındaki
   anlara (başlangıç, durum değişimleri, bitiş) karşılık gelir; dokununca videoda o ana gidilir.
   İsteğe bağlı olarak takip kutusu ve iz videonun üzerine çizilir (ham video ayrıca saklanır).
10. **Ölçülen değerler:** 06'daki ölçüt tablosunun aynısı.
11. **Olay kaydı:** Test süresince olan durum/yön değişimleri, kopmalar ve bitiş nedeni,
    test başlangıcına göre zaman damgalı. Telemetri özeti (alınan paket, kopma sayısı).
12. **Test koşulları:** Kalibrasyon ölçeği, beklenen yön, hedef bölge vb. (değerlendirmede kullanılan girdiler).
13. **Doğrulama:** Tam doğrulama özeti (ör. SHA-256), mühürlenme anı ve **Bütünlüğü doğrula**
    düğmesi. Düğme özeti dosyalardan yeniden hesaplayıp kayıtlı özetle karşılaştırır:
    `✓ değişmemiş` ya da `✕ eşleşmiyor`.
14. **DIŞA AKTAR:** Raporu ve videoyu telefonun paylaşım/kaydetme seçenekleriyle dışarı verir.

### Durumlar

**Bütünlük doğrulanamadı**
```text
┌──────────────────────────────────────┐
│ ← Rapor · 13.10.2026 14:32           │
│ [KİLİTLİ] Değiştirilemez kayıt       │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │ ! BÜTÜNLÜK DOĞRULANAMADI       │  │
│  ├────────────────────────────────┤  │
│  │ Kayıt dosyaları mühürlendiği   │  │
│  │ andaki özetle eşleşmiyor.      │  │
│  │ Bu rapor güvenilir değil.      │  │
│  └────────────────────────────────┘  │
│   (Rapor içeriği salt okunur olarak  │
│    gösterilmeye devam eder.)         │
│ DOĞRULAMA                            │
│   Kayıtlı özet : 3f9a…b41d           │
│   Hesaplanan   : 77c0…e912   ✕       │
└──────────────────────────────────────┘
```

**Dışa aktarma**
```text
┌──────────────────────────────────────┐
│ DIŞA AKTAR                           │
├──────────────────────────────────────┤
│ Neler dışa aktarılsın?               │
│   [x] Rapor (ölçümler, karar,        │
│       olay kaydı, doğrulama özeti)   │
│   [x] Video                          │
│                                      │
│ Dışa aktarılan kopya da aynı         │
│ doğrulama özetini taşır.             │
│                                      │
│  ┌────────────────────────────────┐  │
│  │        PAYLAŞ / KAYDET         │  │
│  └────────────────────────────────┘  │
│ [ Vazgeç ]                           │
└──────────────────────────────────────┘
```

| Durum | Davranış |
| --- | --- |
| Video yok | Oynatıcı yerine "Video kaydedilemedi, zaman damgalı kayıt gösteriliyor" notu; olay kaydı genişler. |
| Video dosyası bulunamadı | Oynatıcıda "Video bulunamadı" ve bütünlük doğrulaması `✕`. |
| Bütünlük ✕ | Üstte uyarı kutusu; rapor yine gösterilir ama "güvenilir değil" olarak işaretlenir. |
| Dışa aktarma hatası | "Dışa aktarılamadı (depolama/izin)" uyarısı, tekrar dene. |

## Geçişler
- 07a satırı → 07b
- 07b ← → 07a (ya da geldiği 06)
- 07a ← → 01 veya 02 (nereden açıldıysa)
