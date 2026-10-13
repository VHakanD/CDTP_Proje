# 06 · Sonuç Ekranı

[← Ekran dizini](README.md) · Önceki: [05 · Kamera + HUD](05-kamera-hud.md) · Sonraki: [07 · Rapor Geçmişi ve Detayı](07-rapor-gecmisi-ve-detay.md)

## Amaç
Test biter bitmez uygulamanın otomatik verdiği **GEÇTİ / KALDI** kararını, ölçülen
değerleri ve her ölçütün tek tek geçip geçmediğini göstermek. Sonuç bu ekran açılmadan
önce kilitlenir (mühürlenir) ve **düzenlenemez**.

## Wireframe — GEÇTİ (Görev B örneği)
```text
┌──────────────────────────────────────┐
│ Test Sonucu                      [1] │
│ Görev B · Robot Yönlendirmesi        │
│ 13.10.2026  14:32:05 → 14:32:19      │
├──────────────────────────────────────┤
│  ┌─────────────────────────────┐     │
│  │                             │     │
│  │          G E Ç T İ          │     │
│  │                             │ [2] │
│  │     3 / 3 ölçüt sağlandı    │     │
│  └─────────────────────────────┘     │
│ ÖLÇÜTLER                         [3] │
│  ┌────────────────────────────────┐  │
│  │ Ölçüt       Ölçülen    Sonuç   │  │
│  ├────────────────────────────────┤  │
│  │ Yön         İleri      ✓ geçti │  │
│  │   hedef: İleri                 │  │
│  │ Mesafe      0,97 m     ✓ geçti │  │
│  │   hedef: 0,8–1,2 m             │  │
│  │ Son konum   durdu      ✓ geçti │  │
│  │   hedef: robot durur           │  │
│  ├────────────────────────────────┤  │
│  │ Süre        14,2 s     bilgi   │  │
│  │ Yük durumu  —          yok     │  │
│  └────────────────────────────────┘  │
│ KAYIT                            [4] │
│  ┌────────────────────────────────┐  │
│  │ ▶  Video · 00:14               │  │
│  │    + zaman damgalı olay kaydı  │  │
│  └────────────────────────────────┘  │
│ [KİLİTLİ] Kayıt mühürlendi       [5] │
│ SHA-256: 3f9a7c2e … 91d0b41d         │
│ Kayıt anı: 13.10.2026 14:32:20       │
│                                      │
│  ┌─────────────────────────────┐     │
│  │          RAPORU AÇ          │ [6] │
│  └─────────────────────────────┘     │
│ [ Yeni Test ]   [ Ana Panel ]    [7] │
└──────────────────────────────────────┘
```

## Öğeler
1. **Başlık ve test bilgisi:** Görev adı, başlangıç ve bitiş zaman damgaları.
2. **Karar kutusu:** Büyük `GEÇTİ` ya da `KALDI` yazısı ve kaç ölçütün sağlandığı.
   Renk/tema kararı verilmemiştir; karar yazıyla ve simgeyle (✓ / ✕) de okunabilir olmalıdır.
3. **Ölçüt tablosu:** Seçilen göreve ait her ölçüt için ölçülen değer, hedef değer ve sonuç
   (`✓ geçti` / `✕ kaldı` / `ölçülemedi`). Göreve ait olmayan ölçütler `yok` olarak gri
   gösterilir, karara katılmaz. KALDI durumunda kalan ölçüt için kısa bir **neden** satırı vardır.
4. **Kayıt:** Video (ya da video yoksa zaman damgalı olay kaydı) önizlemesi. Dokununca
   rapor detayındaki oynatıcı açılır.
5. **Kilit ve doğrulama özeti:** `[KİLİTLİ]` rozeti, kaydın doğrulama özeti (ör. SHA-256,
   kısaltılmış) ve mühürlenme anı. **Düzenle düğmesi yoktur.**
6. **RAPORU AÇ:** Bu testin rapor detayına gider (07b).
7. **Yeni Test / Ana Panel:** Yeni test için 03'e, ya da 02'ye döner.

### Görevlere göre ölçüt satırları
| Görev | Ölçüt satırları |
| --- | --- |
| A · Statik Denge | Süre (30 s, ±2 s), hareket durumu (statik denge) |
| B · Robot Yönlendirmesi | Yön, mesafe (0,8–1,2 m), son konum |
| C · Şarj Etme | Son konum (istasyon bölgesi), şarj başlangıcı tespit süresi (≤ 5 s), pil/şarj durumu, eğim |
| E · Bütünleşik Görev | Yük durumu (kutu taşındı, düşmedi), son konum (hedef bölge) |

## Durumlar

### KALDI (Görev A örneği)
```text
┌──────────────────────────────────────┐
│ Test Sonucu                          │
│ Görev A · Statik Denge               │
│ 13.10.2026  14:40:02 → 14:40:23      │
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  │           K A L D I            │  │
│  │                                │  │
│  │      1 / 2 ölçüt sağlandı      │  │
│  └────────────────────────────────┘  │
│ ÖLÇÜTLER                             │
│  ┌────────────────────────────────┐  │
│  │ Ölçüt       Ölçülen    Sonuç   │  │
│  ├────────────────────────────────┤  │
│  │ Süre        21,3 s     ✕ kaldı │  │
│  │   hedef: 30 s (±2 s)           │  │
│  │   neden: 21,3 s'de denge       │  │
│  │   bozuldu (eğim sınırı aşıldı) │  │
│  │ Hareket     statik     ✓ geçti │  │
│  │   hedef: statik denge          │  │
│  ├────────────────────────────────┤  │
│  │ Mesafe      —          yok     │  │
│  │ Yük durumu  —          yok     │  │
│  └────────────────────────────────┘  │
│ KAYIT                                │
│  ┌────────────────────────────────┐  │
│  │ ▶  Video · 00:21               │  │
│  │    + zaman damgalı olay kaydı  │  │
│  └────────────────────────────────┘  │
│ [KİLİTLİ] Kayıt mühürlendi           │
│ SHA-256: c07e19a4 … 5e22f80c         │
│                                      │
│  ┌────────────────────────────────┐  │
│  │           RAPORU AÇ            │  │
│  └────────────────────────────────┘  │
│ [ Yeni Test ]   [ Ana Panel ]        │
└──────────────────────────────────────┘
```

### Hesaplanıyor / mühürleniyor
```text
┌──────────────────────────────────────┐
│ Test Sonucu                          │
│ Görev B · Robot Yönlendirmesi        │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐  │
│  │                                │  │
│  │      Sonuç hesaplanıyor…       │  │
│  │                                │  │
│  │     Video kaydediliyor ve      │  │
│  │      kayıt mühürleniyor.       │  │
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
│   (Bu sırada geri dönülemez.)        │
└──────────────────────────────────────┘
```

| Durum | Davranış |
| --- | --- |
| Hesaplanıyor | Kısa bekleme ekranı. Kayıt mühürlenmeden sonuç gösterilmez. |
| GEÇTİ | Tüm görev ölçütleri ✓. |
| KALDI | En az bir ölçüt ✕; kalan ölçüt(ler) tabloda en üstte ve neden satırıyla. |
| Ölçülemedi | Bir ölçüt ölçülemediyse (ör. robot kadrajdan çıktı, ölçek yok) satırda `ölçülemedi` yazar ve karar KALDI olur. Neden satırında sebep gösterilir. |
| Test kesintiye uğradı | Karar yerine `TEST KESİLDİ` gösterilir; kayıt yine mühürlenir ve geçmişte görünür. |
| Video kaydedilemedi | Kayıt alanında "Video yok, zaman damgalı kayıt saklandı" notu. |

## Geçişler
- **RAPORU AÇ** → [07b · Rapor Detayı](07-rapor-gecmisi-ve-detay.md#07b--rapor-detayı)
- **Yeni Test** → [03 · Görev Seçimi](03-gorev-secimi.md)
- **Ana Panel** → [02 · Ana Panel](02-ana-panel.md)
- Geri tuşu → 02 (05'e geri dönülmez, test bitmiştir)
