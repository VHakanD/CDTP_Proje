# 01 · Bağlantı Ekranı

[← Ekran dizini](README.md) · Sonraki: [02 · Ana Panel](02-ana-panel.md)

## Amaç
Uygulama açıldığında robotu bulup kablosuz bağlantıyı kurmak ve bağlantının
gerçekten çalıştığını (ilk telemetri paketi geldi mi) arayüzde doğrulamak.
Bağlantı türü (BLE / Wi-Fi) henüz belli olmadığı için ekranda yalnızca
"bağlantı" ifadesi kullanılır.

## Wireframe — varsayılan (bağlı değil)
```text
┌──────────────────────────────────────┐
│ Robot Bağlantısı                 [1] │
├──────────────────────────────────────┤
│                                      │
│ Durum: ○ Bağlı değil             [2] │
│                                      │
│ Bulunan robotlar                 [3] │
│  ┌────────────────────────────────┐  │
│  │ ● CDTP-Robot-01      (seçili)  │  │
│  │   sinyal: güçlü                │  │
│  ├────────────────────────────────┤  │
│  │ ○ CDTP-Robot-02                │  │
│  │   sinyal: orta                 │  │
│  └────────────────────────────────┘  │
│ [ ↻ Yeniden Tara ]               [4] │
│                                      │
│  ┌─────────────────────────────┐     │
│  │            BAĞLAN           │ [5] │
│  └─────────────────────────────┘     │
│                                      │
│ Bağlantı doğrulama               [6] │
│  [ ] Robot bulundu                   │
│  [ ] Bağlantı açıldı                 │
│  [ ] İlk telemetri paketi alındı     │
│                                      │
│ Rapor geçmişi →                  [7] │
└──────────────────────────────────────┘
```

## Öğeler
1. **Başlık:** Ekranın adı.
2. **Durum satırı:** `○ Bağlı değil` / `◌ Bağlanıyor…` / `● Bağlı` / `✕ Bağlantı kurulamadı`.
3. **Bulunan robotlar listesi:** Taramada bulunan robotlar ve sinyal düzeyi. Biri seçilir.
4. **Yeniden Tara:** Listeyi yeniler.
5. **BAĞLAN:** Seçili robota bağlanır. Liste boşsa ya da seçim yoksa pasif.
6. **Bağlantı doğrulama listesi:** Bağlantının üç adımı tek tek işaretlenir. Son adım
   ("ilk telemetri paketi alındı") işaretlenmeden bağlantı "kuruldu" sayılmaz.
   Şartnamedeki "bağlantının kurulduğu arayüzde doğrulanır" maddesini karşılar.
7. **Rapor geçmişi:** Robota bağlanmadan da eski raporlar açılabilir (→ 07).

## Durumlar

### Bağlanıyor
```text
┌──────────────────────────────────────┐
│ Robot Bağlantısı                     │
├──────────────────────────────────────┤
│                                      │
│ Durum: ◌ Bağlanıyor… CDTP-Robot-01   │
│                                      │
│ Bağlantı doğrulama                   │
│  [x] Robot bulundu                   │
│  [x] Bağlantı açıldı                 │
│  [ ] İlk telemetri paketi bekleniyor │
│                                      │
│  ┌────────────────────────────────┐  │
│  │             İPTAL              │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### Bağlandı ve doğrulandı
```text
┌──────────────────────────────────────┐
│ Robot Bağlantısı                     │
├──────────────────────────────────────┤
│                                      │
│ Durum: ● Bağlı — CDTP-Robot-01       │
│                                      │
│ Bağlantı doğrulama                   │
│  [x] Robot bulundu                   │
│  [x] Bağlantı açıldı                 │
│  [x] İlk telemetri paketi alındı     │
│      (pil %72 · eğim +0,8°)          │
│                                      │
│  ┌────────────────────────────────┐  │
│  │         ANA PANELE GEÇ         │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### Hata — bağlantı kurulamadı
```text
┌──────────────────────────────────────┐
│ Robot Bağlantısı                     │
├──────────────────────────────────────┤
│                                      │
│ Durum: ✕ Bağlantı kurulamadı         │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ Robot yanıt vermedi.           │  │
│  │ Robotun açık ve yakında        │  │
│  │ olduğunu kontrol edin.         │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │          TEKRAR DENE           │  │
│  └────────────────────────────────┘  │
│ [ ↻ Yeniden Tara ]                   │
└──────────────────────────────────────┘
```

| Durum | Davranış |
| --- | --- |
| Boş liste | "Robot bulunamadı. Robotun açık olduğundan emin olun." metni ve **Yeniden Tara**. BAĞLAN pasif. |
| Bağlanıyor | Liste ve BAĞLAN kilitlenir, **İPTAL** görünür. Doğrulama adımları sırayla işaretlenir. |
| Bağlandı | Üç adım da işaretli, ilk paketteki pil ve eğim değeri gösterilir, **ANA PANELE GEÇ** aktif. |
| Kurulamadı | Hata kutusu, **TEKRAR DENE** ve **Yeniden Tara**. |
| Telefonda kablosuz bağlantı kapalı | "Bağlantı için kablosuz özelliği açın." uyarısı (izin ya da ayar ekranına yönlendirme). |
| Başka ekrandayken bağlantı koptu | Kullanıcı bu ekrana döner, durum satırında "Bağlantı koptu (son paket X s önce)" yazar. |

## Geçişler
- **ANA PANELE GEÇ** → [02 · Ana Panel](02-ana-panel.md)
- **Rapor geçmişi →** → [07 · Rapor Geçmişi](07-rapor-gecmisi-ve-detay.md)
