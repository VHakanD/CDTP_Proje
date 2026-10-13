# 04 · Kamera Kalibrasyonu / Sahne Hazırlama

[← Ekran dizini](README.md) · Önceki: [03 · Görev Seçimi](03-gorev-secimi.md) · Sonraki: [05 · Kamera + HUD](05-kamera-hud.md)

## Amaç
Test başlamadan önce telefonun sabit durduğunu, piksel→metre ölçeğinin bilindiğini ve
robotun kadrajda algılandığını doğrulamak. Mesafe (0,8–1,2 m) ve son konum ölçümleri
bu ekranda alınan değerlere dayanır.

## Wireframe — tüm adımlar tamam (Görev C örneği)
```text
┌──────────────────────────────────────┐
│ ← Sahne Hazırlama  ·  Görev C    [1] │
│ ● Bağlı · 0,4 s                      │
├──────────────────────────────────────┤
│  ┌─ KAMERA ÖNİZLEME ──────────────┐  │
│  │                                │  │
│  │  P1 ●──────────────● P2  [2]   │  │
│  │      1,00 m işaret             │  │
│  │                                │  │
│  │   ┌───────┐                    │  │
│  │   │ ROBOT │ [3]                │  │
│  │   └───────┘                    │  │
│  │    × başlangıç     ┌ ─ ─ ─ ┐   │  │
│  │                    │ hedef │   │  │
│  │                    └ ─ ─ ─ ┘   │  │
│  │                                │  │
│  └────────────────────────────────┘  │
│ 1. Telefonu sabitle              [4] │
│    [x] Telefon sabit, alan kadrajda  │
│ 2. Ölçek                         [5] │
│    [x] P1 ve P2'ye dokunuldu         │
│    Uzunluk: [ 1,00 ] m               │
│    Ölçek  : 412 px/m  (P1–P2 412 px) │
│ 3. Robot kadrajda                [6] │
│    [x] Robot algılandı               │
│ 4. Hedef bölge (C ve E)          [7] │
│    [x] Şarj istasyonu bölgesi çizildi│
│                                      │
│ [ Sıfırla ]                      [8] │
│  ┌─────────────────────────────┐     │
│  │  HAZIR: KAMERA EKRANINA GEÇ │ [9] │
│  └─────────────────────────────┘     │
└──────────────────────────────────────┘
```

## Öğeler
1. **Başlık:** Seçili görev adı ile birlikte. Geri oku 03'e döner.
2. **Ölçek işareti (P1–P2):** Kullanıcı, zemine konmuş bilinen uzunluktaki işaretin
   (ör. 1,00 m bant) iki ucuna önizleme üzerinde dokunur. İki nokta arasında çizgi çizilir;
   noktalar sürüklenerek düzeltilebilir.
3. **Robot algılama kutusu:** Görüntü işleme robotu bulunca etrafına kutu çizer ve
   o anki konumu **başlangıç konumu** (×) olarak kaydeder.
4. **Adım 1, Telefonu sabitle:** Kullanıcının işaretlediği onay kutusu ("telefon sabit
   ve hareket alanı kadrajda").
5. **Adım 2, Ölçek:** Bilinen uzunluk girilir (varsayılan 1,00 m). Uygulama P1–P2
   piksel uzaklığından ölçeği (px/m) hesaplayıp gösterir.
6. **Adım 3, Robot kadrajda:** Robot algılanınca otomatik işaretlenir.
7. **Adım 4, Hedef bölge (yalnızca C ve E):** Şarj istasyonunun (C) ya da ilaç kutusunun
   bırakılacağı hedefin (E) bulunduğu bölge önizleme üzerinde dikdörtgen olarak çizilir.
   "Son konum" ölçütü bu bölgeye göre değerlendirilir.
8. **Sıfırla:** Noktaları, ölçeği ve bölgeyi temizler.
9. **HAZIR: KAMERA EKRANINA GEÇ:** Gerekli adımlar tamamlanınca aktif olur.
   Ölçek ve bölge bilgisi teste (ve rapora) eklenir.

### Göreve göre gerekli adımlar
| Adım | A | B | C | E |
| --- | --- | --- | --- | --- |
| 1 · Telefon sabit | Zorunlu | Zorunlu | Zorunlu | Zorunlu |
| 2 · Ölçek | İsteğe bağlı | **Zorunlu** (mesafe) | İsteğe bağlı | İsteğe bağlı |
| 3 · Robot kadrajda | Zorunlu | Zorunlu | Zorunlu | Zorunlu |
| 4 · Hedef bölge | — | — | **Zorunlu** | **Zorunlu** |

## Durumlar

### Eksik adımlar / robot algılanamadı (Görev B örneği)
```text
┌──────────────────────────────────────┐
│ ← Sahne Hazırlama  ·  Görev B        │
│ ● Bağlı · 0,4 s                      │
├──────────────────────────────────────┤
│  ┌─ KAMERA ÖNİZLEME ──────────────┐  │
│  │                                │  │
│  │  İşaretin iki ucuna dokunun    │  │
│  │                                │  │
│  │                                │  │
│  │                                │  │
│  │   ? robot görünmüyor           │  │
│  │                                │  │
│  │                                │  │
│  │                                │  │
│  │                                │  │
│  │                                │  │
│  └────────────────────────────────┘  │
│ 1. Telefonu sabitle                  │
│    [x] Telefon sabit, alan kadrajda  │
│ 2. Ölçek                             │
│    [ ] P1 ve P2'ye dokunun           │
│ 3. Robot kadrajda                    │
│    [ ] ! Robot algılanamadı.         │
│        Robotu kadraja alın, ışığı    │
│        kontrol edin.                 │
│ 4. Hedef bölge  (B için gerekmez)    │
│                                      │
│  ┌────────────────────────────────┐  │
│  │         HAZIR (pasif)          │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

| Durum | Davranış |
| --- | --- |
| Başlangıç | Önizleme açık, adımlar boş, HAZIR pasif. |
| Kamera izni yok | Önizleme yerine "Kamera izni gerekli" ve izin isteme düğmesi. |
| Ölçek geçersiz | P1–P2 çok yakınsa (birkaç piksel) ya da uzunluk 0 girildiyse: "Noktalar çok yakın / uzunluk geçersiz" uyarısı. |
| Robot algılanamadı | Adım 3'te uyarı metni, HAZIR pasif. |
| Robot kadrajdan çıktı | Adım 3'ün işareti kalkar, HAZIR tekrar pasif olur. |
| Telefon yönü değişti | Kalibrasyon test yönüne (dikey/yatay) bağlıdır. Yön değişirse "Kalibrasyonu yenileyin" uyarısı çıkar, adım 2–4 sıfırlanır. |
| Bağlantı koptu | Üstteki rozet `○ Koptu`, HAZIR pasif. |

## Geçişler
- **HAZIR** → [05 · Kamera + HUD](05-kamera-hud.md) (test henüz başlamamış "hazır" durumunda açılır)
- **←** → [03 · Görev Seçimi](03-gorev-secimi.md)
