# 02 · Ana Panel / Canlı Sensör Ekranı

[← Ekran dizini](README.md) · Önceki: [01 · Bağlantı](01-baglanti.md) · Sonraki: [03 · Görev Seçimi](03-gorev-secimi.md)

## Amaç
Robottan 1 Hz ile gelen şarj durumu, pil yüzdesi ve eğim açısını canlı göstermek;
bağlantının sağlıklı olduğunu (son paketten bu yana geçen süre) sürekli görünür kılmak.
Test öncesi "robot hazır mı?" kontrolü bu ekranda yapılır.

## Wireframe
```text
┌──────────────────────────────────────┐
│ Ana Panel            CDTP-Robot-01   │
│ ● Bağlı · son paket 0,4 s önce   [1] │
├──────────────────────────────────────┤
│ ŞARJ / PİL                       [2] │
│  ┌────────────────────────────────┐  │
│  │ Pil   [███████████░░░░░]  %72  │  │
│  │ Şarj: ŞARJ OLMUYOR             │  │
│  └────────────────────────────────┘  │
│ EĞİM AÇISI                       [3] │
│  ┌────────────────────────────────┐  │
│  │ Anlık eğim:      +3,4°         │  │
│  │                                │  │
│  │   -30  -15   0   +15  +30      │  │
│  │   ├────┼────┼────┼────┤        │  │
│  │               ▲                │  │
│  │             +3,4°              │  │
│  └────────────────────────────────┘  │
│ EĞİM — SON 60 s                  [4] │
│  ┌────────────────────────────────┐  │
│  │ +10° ┤          ╭─╮            │  │
│  │   0° ┼──╮ ╭─────╯ ╰──╮  ╭──    │  │
│  │ -10° ┤  ╰─╯          ╰──╯      │  │
│  │      └──────────────────────   │  │
│  │      -60 s             şimdi   │  │
│  └────────────────────────────────┘  │
│ BAĞLANTI SAĞLIĞI                 [5] │
│  ┌────────────────────────────────┐  │
│  │ Son paket   : 0,4 s önce       │  │
│  │ Paket hızı  : 1,0 Hz           │  │
│  │ 0 s [██░░░░░░░░░░░░░░░] 2 s    │  │
│  │     (kopma sınırı 2 s)         │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌─────────────────────────────┐     │
│  │          GÖREV SEÇ          │ [6] │
│  └─────────────────────────────┘     │
│ Rapor geçmişi →                  [7] │
│ Bağlantıyı kes                   [8] │
└──────────────────────────────────────┘
```

## Öğeler
1. **Bağlantı rozeti:** Robot adı, bağlantı simgesi ve son paketten bu yana geçen süre.
   Bu rozet 02–05 arasındaki tüm ekranların üst kısmında aynı biçimde tekrarlanır.
   - `● Bağlı`: son paket ≤ 1,5 s önce
   - `◐ Gecikme`: 1,5 s – 2 s arası
   - `○ Koptu`: 2 s'den fazla
2. **Şarj / Pil kartı:** Pil yüzdesi (çubuk + sayı) ve şarj durumu
   (`ŞARJ OLUYOR` / `ŞARJ OLMUYOR`). Her paket geldiğinde (1 Hz) güncellenir.
3. **Eğim göstergesi:** Anlık eğim açısı (°), büyük sayı ve ölçekli çubuk üzerinde işaretçi.
   Ölçek aralığı (burada ±30°) Modül A ile birlikte belirlenecek.
4. **Eğim grafiği:** Son 60 saniyenin eğim değerleri (1 Hz → 60 nokta), sağdan sola kayar.
5. **Bağlantı sağlığı kartı:** Son paketten bu yana geçen süre, ölçülen paket hızı
   ve 0–2 s arasında dolan bir çubuk. Çubuk 2 s'ye ulaşırsa bağlantı "koptu" sayılır.
6. **GÖREV SEÇ:** Test akışını başlatır. Bağlantı yokken pasif.
7. **Rapor geçmişi:** → 07.
8. **Bağlantıyı kes:** Onay sorusundan sonra bağlantıyı kapatır ve 01'e döner.

## Durumlar

### Gecikme (1,5 – 2 s)
```text
┌──────────────────────────────────────┐
│ Ana Panel            CDTP-Robot-01   │
│ ◐ Gecikme · son paket 1,7 s önce     │
├──────────────────────────────────────┤
│ ŞARJ / PİL                           │
│  ┌────────────────────────────────┐  │
│  │ Pil   [███████████░░░░░]  %72  │  │
│  │ Şarj: ŞARJ OLMUYOR             │  │
│  └────────────────────────────────┘  │
│ BAĞLANTI SAĞLIĞI                     │
│  ┌────────────────────────────────┐  │
│  │ Son paket   : 1,7 s önce       │  │
│  │ Paket hızı  : 0,6 Hz           │  │
│  │ 0 s [████████████████░░] 2 s   │  │
│  │ ! Bağlantı zayıflıyor          │  │
│  └────────────────────────────────┘  │
│   (diğer kartlar aynı, son değerler) │
└──────────────────────────────────────┘
```

### Bağlantı koptu (> 2 s)
```text
┌──────────────────────────────────────┐
│ Ana Panel            CDTP-Robot-01   │
│ ○ Koptu · son paket 2,6 s önce       │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐  │
│  │ BAĞLANTI KOPTU                 │  │
│  ├────────────────────────────────┤  │
│  │ Son paket 2,6 s önce alındı.   │  │
│  │ Yeniden bağlanılıyor… (2/5)    │  │
│  │                                │  │
│  │ Gösterilen değerler eski.      │  │
│  ├────────────────────────────────┤  │
│  │ [ Bağlantı ekranına dön ]      │  │
│  └────────────────────────────────┘  │
│                                      │
│   Pil   %72          (eski)          │
│   Eğim  +3,4°        (eski)          │
│                                      │
│  ┌────────────────────────────────┐  │
│  │       GÖREV SEÇ  (pasif)       │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

| Durum | Davranış |
| --- | --- |
| İlk veriler bekleniyor | Kartlarda `—` gösterilir, grafik boş, "Veri bekleniyor…" yazısı. |
| Gecikme | Rozet `◐`, sağlık çubuğu dolar, "Bağlantı zayıflıyor" uyarısı. Değerler son geçerli haliyle kalır. |
| Koptu | Üstte kapatılamayan uyarı kutusu, otomatik yeniden bağlanma denemeleri, değerler "eski" olarak işaretlenir, GÖREV SEÇ pasif. |
| Yeniden bağlandı | Uyarı kaybolur, grafikte kopukluk süresi boşluk olarak kalır. |
| Yeniden bağlanılamadı | "Bağlantı ekranına dön" ile 01'e gidilir. |
| Geçersiz değer (ör. pil > %100) | İlgili kartta `—` ve "geçersiz veri" notu. |

## Geçişler
- **GÖREV SEÇ** → [03 · Görev Seçimi](03-gorev-secimi.md)
- **Rapor geçmişi →** → [07 · Rapor Geçmişi](07-rapor-gecmisi-ve-detay.md)
- **Bağlantıyı kes** veya yeniden bağlanılamadı → [01 · Bağlantı](01-baglanti.md)
