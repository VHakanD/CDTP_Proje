# 03 · Görev Seçimi

[← Ekran dizini](README.md) · Önceki: [02 · Ana Panel](02-ana-panel.md) · Sonraki: [04 · Kalibrasyon](04-kalibrasyon-sahne.md)

## Amaç
Kullanıcının dört görevden birini seçmesini sağlamak. Her görevin başarı ölçütü ve
otomatik bitiş koşulu kartın üzerinde yazılıdır; böylece kullanıcı testin neye göre
değerlendirileceğini test başlamadan görür.

## Wireframe
```text
┌──────────────────────────────────────┐
│ ← Görev Seçimi                   [1] │
│ ● Bağlı · 0,4 s · pil %72 · +0,8°    │
├──────────────────────────────────────┤
│ Bir görev seçin:                 [2] │
│  ┌────────────────────────────────┐  │
│  │ ○ Statik Denge         Modül A │  │
│  │   Başarı: 30 s dengede kalma   │  │
│  │   Bitiş : 30 s dolunca ya da   │  │
│  │           denge bozulunca      │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ ● Robot Yönlendirmesi  Modül B │  │
│  │   Başarı: doğru yön +          │  │
│  │           mesafe 0,8–1,2 m     │  │
│  │   Bitiş : robot durunca        │  │
│  ├────────────────────────────────┤  │
│  │ Beklenen yön: [ İleri ▾ ]   [3]│  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ ○ Şarj Etme            Modül C │  │
│  │   Başarı: şarj başlangıcı      │  │
│  │           5 s içinde tespit    │  │
│  │           (kamera + eğim + pil)│  │
│  │   Bitiş : şarj başlayınca      │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ ○ Bütünleşik Görev     Modül E │  │
│  │   Başarı: ilaç kutusu          │  │
│  │           başarıyla taşınır    │  │
│  │   Bitiş : robot hedefte durunca│  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌─────────────────────────────┐     │
│  │    DEVAM: SAHNE HAZIRLAMA   │ [4] │
│  └─────────────────────────────┘     │
└──────────────────────────────────────┘
```

## Öğeler
1. **Başlık ve geri oku:** 02'ye döner. Altında kısa bağlantı rozeti (bağlantı + pil + eğim).
2. **Görev kartları (tek seçim):** Her kartta görev adı, modül harfi, başarı metriği ve
   otomatik bitiş koşulu bulunur. Seçili kart `●`, diğerleri `○` ile gösterilir.
3. **Beklenen yön seçici (yalnızca Modül B):** İleri / Geri / Sağ / Sol. Uygulamanın
   "doğru yön" ölçütünü değerlendirebilmesi için gereklidir; kart seçilince açılır.
4. **DEVAM: SAHNE HAZIRLAMA:** Görev seçilmeden (ve B için yön seçilmeden) pasif.

### Görevlere göre değerlendirme ölçütleri
Sonuç ekranında (06) kullanılacak ölçütler:

| Görev | Kullanılan ölçütler | Otomatik bitiş koşulu (varsayım) |
| --- | --- | --- |
| A · Statik Denge | Süre: 30 s (tolerans ±2 s), hareket durumu boyunca "statik denge" | 30 s dolar ya da denge bozulur (eğim sınırı aşılır / robot devrilir) |
| B · Robot Yönlendirmesi | Yön = beklenen yön, mesafe 0,8–1,2 m, son konum (robot durdu) | Robot hareket ettikten sonra belirli bir süre durağan kalır |
| C · Şarj Etme | Son konum = şarj istasyonu, şarj başlangıcının ≤ 5 s içinde tespiti (kamera + eğim + pil) | Robottan "şarj oluyor" bilgisi gelir ya da süre aşılır |
| E · Bütünleşik Görev | Yükün durumu (kutu robot üzerinde, düşmedi), son konum = hedef bölge | Robot hedef bölgede durur |

## Durumlar
| Durum | Davranış |
| --- | --- |
| Seçim yok | DEVAM pasif, "Bir görev seçin" ipucu. |
| B seçili, yön seçilmemiş | DEVAM pasif, yön seçici vurgulanır. |
| Bağlantı koptu | 02'deki kopma uyarısı burada da çıkar, DEVAM pasif. |
| Pil düşük (ör. < %20) | Seçili kartın altında "Pil düşük, test yarıda kalabilir" uyarısı (engellemez). |

## Geçişler
- **DEVAM** → [04 · Kamera Kalibrasyonu / Sahne Hazırlama](04-kalibrasyon-sahne.md)
- **←** → [02 · Ana Panel](02-ana-panel.md)
