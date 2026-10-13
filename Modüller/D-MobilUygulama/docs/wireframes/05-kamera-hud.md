# 05 · Kamera + HUD (Canlı Test) Ekranı

[← Ekran dizini](README.md) · Önceki: [04 · Kalibrasyon](04-kalibrasyon-sahne.md) · Sonraki: [06 · Sonuç](06-sonuc.md)

## Amaç
Testi başlatmak, kamera kaydı sürerken robotu takip etmek ve canlı bilgileri (süre,
şarj/pil, eğim, hareket durumu, yön) kamera görüntüsünün üzerinde göstermek.
Ekip kararıyla HUD'a ayrıca **canlı kat edilen mesafe** ve **takip güveni** eklenmiştir;
hareket izi ikincil öğedir.
Test "Testi Bitir" ile ya da otomatik bitiş koşulu algılanınca biter.

HUD yerleşimi henüz kesinleşmediği için **iki varyant** çizilmiştir:
- **Varyant A:** Bilgiler köşelere dağıtılmış, görüntünün ortası boş kalır.
- **Varyant B:** Üstte büyük yön oku, diğer bilgiler alttaki tek şeritte toplanır.

Her iki varyant da dikey ve yatay tutuşta gösterilmiştir. Öğe numaraları iki varyantta aynıdır.

## Hazır durumu (test başlamadı)
04'ten gelindiğinde ekran bu durumda açılır. HUD değerleri canlıdır ama sayaç 0'da
bekler ve kayıt yapılmaz.

```text
┌──────────────────────────────────────┐
│ ○ kayıt yok        ● Bağlı 0,4 s [2] │
│ Görev B · Robot Yönlendirmesi        │
│                                      │
│ ┌─────────────┐    ┌───────────────┐ │
│ │ SÜRE        │    │ PİL %72       │ │
│ │ 00:00,0     │    │ şarj yok      │ │
│ └─────────────┘    │ EĞİM +0,8°    │ │
│                    └───────────────┘ │
│                                      │
│                                      │
│                                      │
│              ┌───────┐               │
│              │ ROBOT │               │
│              └───────┘               │
│             robot algılandı          │
│                                      │
│                                      │
│    ┌────────────────────────────┐    │
│    │                            │    │
│    │      ▶  TESTİ BAŞLAT       │    │
│    │                            │    │
│    └────────────────────────────┘    │
│                                      │
│    Başlangıç zaman damgası alınır    │
│    ve kamera kaydı başlar.           │
└──────────────────────────────────────┘
```

- **▶ TESTİ BAŞLAT:** Başlangıç zaman damgasını alır, kamera kaydını başlatır, sayacı çalıştırır.
  Düğme, test süresince **■ TESTİ BİTİR** düğmesine dönüşür.
- Bağlantı yoksa ya da robot kadrajda değilse pasiftir.

## Varyant A — köşelere dağıtılmış

### A · Dikey
```text
┌──────────────────────────────────────┐
│ ● KAYIT 00:12 [1]  ● Bağlı 0,4 s [2] │
│ Görev B · Robot Yönlendirmesi        │
│                                      │
│ ┌───────────────┐  ┌───────────────┐ │
│ │ SÜRE       [3]│  │ [4] PİL  %72  │ │
│ │ 00:12,4       │  │     şarj yok  │ │
│ ├───────────────┤  │ [5] EĞİM +3,4°│ │
│ │ MESAFE    [11]│  └───────────────┘ │
│ │ 0,64 m        │                    │
│ │ / 0,8–1,2 m   │                    │
│ └───────────────┘                    │
│             Robot görünüyor %92 [12] │
│              ┌───────┐               │
│              │ ROBOT │ [7]           │
│              └───────┘               │
│                  ·                   │
│                  ·                   │
│                 ·  [8] iz            │
│                ·                     │
│               ×  başlangıç           │
│                                      │
│                                      │
│                    ┌───────────────┐ │
│ ┌───────────────┐  │ YÖN        [9]│ │
│ │ HAREKET [6]   │  │       ▲       │ │
│ │ hareket       │  │      ▲▲▲      │ │
│ │ ediyor        │  │     ▲▲▲▲▲     │ │
│ └───────────────┘  │      ███      │ │
│                    │      ███      │ │
│                    │     İLERİ     │ │
│                    └───────────────┘ │
│    ┌────────────────────────────┐    │
│    │    ■  TESTİ BİTİR  [10]    │    │
│    └────────────────────────────┘    │
└──────────────────────────────────────┘
```

### A · Yatay
```text
┌──────────────────────────────────────────────────────────────────────┐
│ ● KAYIT 00:12 [1]                                  ● Bağlı 0,4 s [2] │
│ Görev B · Robot Yönlendirmesi                                        │
│                                                                      │
│ ┌───────────────┐                                  ┌───────────────┐ │
│ │ SÜRE       [3]│                                  │ [4] PİL  %72  │ │
│ │ 00:12,4       │        Robot görünüyor %92 [12]  │     şarj yok  │ │
│ ├───────────────┤        ┌───────┐                 │ [5] EĞİM +3,4°│ │
│ │ MESAFE    [11]│        │ ROBOT │ [7]             └───────────────┘ │
│ │ 0,64 m        │        └───────┘                                   │
│ │ / 0,8–1,2 m   │            ·                                       │
│ └───────────────┘            ·                                       │
│                             ·  [8] iz                                │
│                            ·                       ┌───────────────┐ │
│                           ×  başlangıç             │ YÖN        [9]│ │
│                                                    │       ▲       │ │
│ ┌────────────────┐                                 │      ▲▲▲      │ │
│ │ HAREKET [6]    │                                 │     ▲▲▲▲▲     │ │
│ │ hareket ediyor │    ┌──────────────────────┐     │      ███      │ │
│ └────────────────┘    │ ■  TESTİ BİTİR  [10] │     │      ███      │ │
│                       └──────────────────────┘     │     İLERİ     │ │
│                                                    └───────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

## Varyant B — üstte büyük yön oku + alt şerit

### B · Dikey
```text
┌──────────────────────────────────────┐
│ ● KAYIT 00:12 [1]  ● Bağlı 0,4 s [2] │
│ Görev B · Robot Yönlendirmesi        │
│                                      │
│                  ▲                   │
│                 ▲▲▲                  │
│                ▲▲▲▲▲                 │
│               ▲▲▲▲▲▲▲                │
│                 ███                  │
│                 ███                  │
│               İ L E R İ   [9]        │
│                                      │
│             Robot görünüyor %92 [12] │
│                  ┌───────┐           │
│                  │ ROBOT │ [7]       │
│                  └───────┘           │
│                      ·               │
│                      ·               │
│                     ·  [8] iz        │
│                    ·                 │
│                   ×  başlangıç       │
│                                      │
│                                      │
│ ┌───────────┬───────────┬──────────┐ │
│ │ SÜRE  [3] │ PİL   [4] │ EĞİM [5] │ │
│ │ 00:12,4   │ %72 · yok │ +3,4°    │ │
│ ├───────────┴───────────┴──────────┤ │
│ │ DURUM  [6]   hareket ediyor      │ │
│ │ MESAFE [11]  0,64 m / 0,8–1,2 m  │ │
│ └──────────────────────────────────┘ │
│                                      │
│                                      │
│    ┌────────────────────────────┐    │
│    │    ■  TESTİ BİTİR  [10]    │    │
│    └────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

### B · Yatay
```text
┌──────────────────────────────────────────────────────────────────────┐
│ ● KAYIT 00:12 [1]                                  ● Bağlı 0,4 s [2] │
│ Görev B · Robot Yönlendirmesi                                        │
│                            ▲                            ┌──────────┐ │
│                           ▲▲▲                           │ ■ TESTİ  │ │
│                          ▲▲▲▲▲                          │BİTİR [10]│ │
│                         ▲▲▲▲▲▲▲                         └──────────┘ │
│                           ███                                        │
│                           ███                                        │
│                         İ L E R İ   [9]    Robot görünüyor %92 [12]  │
│                                            ┌───────┐                 │
│                                            │ ROBOT │ [7]             │
│                                            └───────┘                 │
│                                                ·                     │
│                                                ·                     │
│                                               ·  [8] iz              │
│                                              ·                       │
│                                             ×  başlangıç             │
│ ┌──────────┬───────────┬─────────┬────────────────┬─────────────────┐│
│ │ SÜRE [3] │ PİL  [4]  │ EĞİM [5]│ DURUM [6]      │ MESAFE [11]     ││
│ │ 00:12,4  │ %72 · yok │ +3,4°   │ hareket ediyor │ 0,64/0,8–1,2 m  ││
│ └──────────┴───────────┴─────────┴────────────────┴─────────────────┘│
└──────────────────────────────────────────────────────────────────────┘
```

## Öğeler
1. **Kayıt göstergesi:** `● KAYIT` ve kaydın süresi. Kayıt yokken `○ kayıt yok`.
2. **Bağlantı rozeti:** 02'deki rozetin aynısı (son paketten bu yana geçen süre).
3. **Süre sayacı:** "Testi Başlat"tan bu yana geçen süre (dd:ss,o).
4. **Pil / şarj:** Pil yüzdesi ve şarj durumu (1 Hz).
5. **Eğim:** Anlık eğim açısı (1 Hz).
6. **Hareket durumu:** `hareket ediyor` / `dönüyor` / `statik denge` / `toparlanma`.
7. **Takip kutusu:** Görüntü işlemenin bulduğu robotun çevresindeki kutu, robotla birlikte hareket eder.
8. **Hareket izi (ikincil öğe):** Başlangıç konumundan (×) robotun şu anki konumuna kadar
   geçtiği yol. İnce ve geri planda çizilir; diğer HUD öğelerinin önüne geçmez, onları kapatmaz.
9. **Yön göstergesi (ZORUNLU):** `İLERİ` / `GERİ` / `SOL` / `SAĞ`. Büyük ok ve yazı
   birlikte gösterilir; ekrandaki en büyük öğedir. Robot hareket etmiyorsa `—  DURUYOR`.
10. **■ TESTİ BİTİR:** Testi elle bitirir. Yanlışlıkla basılmasın diye bir onay sorulur
    ("Test bitirilsin mi?"). Bitiş zaman damgası alınır, kayıt kapanır.
11. **Kat edilen mesafe (canlı):** Başlangıç konumundan bu yana ölçülen mesafe ve hedef aralık,
    ör. `0,64 m / hedef 0,8–1,2 m`. Kalibrasyondaki piksel→metre ölçeğiyle hesaplanır.
    Ölçek yoksa (04'te atlandıysa) `—` gösterilir.
12. **Takip güveni:** Görüntü işlemenin robotu ne kadar emin gördüğü, ör. `Robot görünüyor %92`.
    Takip kutusunun hemen üstünde durur. Güven düşükse `Robot zor görünüyor %45`,
    robot hiç bulunamazsa `! ROBOT KAYBOLDU` uyarısına dönüşür.

### Yön göstergesi biçimleri
```text
İLERİ       GERİ        SOL         SAĞ      
    ▲          ███         ◀             ▶   
   ▲▲▲         ███        ◀◀             ▶▶  
  ▲▲▲▲▲       ▼▼▼▼▼      ◀◀◀████     ████▶▶▶ 
   ███         ▼▼▼        ◀◀             ▶▶  
   ███          ▼          ◀             ▶   
```

### Varyantların karşılaştırması
| | Varyant A (köşeler) | Varyant B (alt şerit + üst ok) |
| --- | --- | --- |
| Robotun görünürlüğü | Orta alan boş, robot nadiren kapanır | Üst ok ve alt şerit dikey alanı daraltır |
| Yönün belirginliği | Köşede büyük kutu | En belirgin: ortada ve en üstte |
| Bakış hareketi | Göz dört köşe arasında dolaşır | Sayısal bilgiler tek satırda okunur |
| Yatay tutuş | Çok uygun | Uygun (şerit tek satıra iner) |

## Durumlar

### Robot kayboldu + bağlantı koptu (test sırasında)
```text
┌──────────────────────────────────────┐
│ ● KAYIT 00:31 [1]      ○ Koptu 2,4 s │
│ Görev B · Robot Yönlendirmesi        │
│ ┌──────────────────────────────────┐ │
│ │ ! BAĞLANTI KOPTU: şarj/eğim      │ │
│ │   verisi yok. Kayıt sürüyor.     │ │
│ └──────────────────────────────────┘ │
│ ┌───────────────┐  ┌───────────────┐ │
│ │ SÜRE          │  │ PİL %72 (eski)│ │
│ │ 00:31,0       │  │ şarj yok      │ │
│ └───────────────┘  │ EĞİM —        │ │
│                    └───────────────┘ │
│               ! ROBOT KAYBOLDU [12]  │
│      · · · ·  takip %0 · iz kesildi  │
│     ·         mesafe (son): 0,52 m   │
│    × başlangıç                       │
│                    ┌───────────────┐ │
│ ┌───────────────┐  │ YÖN           │ │
│ │ HAREKET       │  │               │ │
│ │ bilinmiyor    │  │               │ │
│ └───────────────┘  │       ?       │ │
│                    │               │ │
│                    │   bilinmiyor  │ │
│                    └───────────────┘ │
│    ┌────────────────────────────┐    │
│    │       ■  TESTİ BİTİR       │    │
│    └────────────────────────────┘    │
└──────────────────────────────────────┘
```

### Otomatik bitiş algılandı
```text
┌──────────────────────────────────────┐
│ ● KAYIT 00:12 [1]  ● Bağlı 0,4 s [2] │
│ Görev B · Robot Yönlendirmesi        │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ BİTİŞ KOŞULU ALGILANDI         │  │
│  ├────────────────────────────────┤  │
│  │ Robot 3 s boyunca durağan.     │  │
│  │ Test 00:14,2'de bitti.         │  │
│  │                                │  │
│  │ Kayıt kapatılıyor ve sonuç     │  │
│  │ hesaplanıyor…                  │  │
│  └────────────────────────────────┘  │
│                                      │
│                                      │
└──────────────────────────────────────┘
```

| Durum | Davranış |
| --- | --- |
| Hazır | Sayaç 0, `○ kayıt yok`, TESTİ BAŞLAT aktif. |
| Test sürüyor | `● KAYIT`, sayaç çalışıyor, HUD 1 Hz (telemetri) ve kamera hızında (takip) güncellenir. |
| Takip güveni düşük | `[12]` öğesi "Robot zor görünüyor %NN" olur; değerler gösterilmeye devam eder. Eşik (ör. %60) ekipçe belirlenecek. |
| Robot kayboldu | `[12]` öğesi `! ROBOT KAYBOLDU` uyarısına dönüşür. Takip kutusu kaybolur, iz son bilinen noktada kesilir, hareket/yön `bilinmiyor`/`?`, mesafe son ölçülen değerde "(son)" notuyla kalır. Kayıt sürer, olay zaman damgasıyla kaydedilir. Robot tekrar bulununca uyarı kalkar. |
| Bağlantı koptu (> 2 s) | Üstte uyarı şeridi, pil/şarj "eski", eğim `—`. Kamera kaydı ve sayaç durmaz. Kopma süresi rapora yazılır. |
| Telefon yönü değişti | Kalibrasyon yöne bağlı olduğu için uyarı: "Telefonu döndürmeyin". Yön kilitlenebilir. |
| Otomatik bitiş | Bilgi kutusu, kayıt kapanır, sonuç hesaplanır → 06. |
| Depolama dolu / kayıt hatası | Test durdurulur, "Kayıt yapılamadı" uyarısı, sonuç üretilmez (geçersiz test). |
| Uygulama arka plana alındı | Test iptal edilmiş sayılır ve rapora "kesintiye uğradı" olarak yazılır. |

## Geçişler
- **TESTİ BİTİR** (onaylı) veya **otomatik bitiş** → [06 · Sonuç](06-sonuc.md)
- Hazır durumunda geri → [04 · Kalibrasyon](04-kalibrasyon-sahne.md). Test sürerken geri tuşu
  "Test iptal edilsin mi?" sorar.
