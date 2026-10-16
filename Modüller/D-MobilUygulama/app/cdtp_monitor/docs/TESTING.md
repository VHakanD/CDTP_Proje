# cdtp_monitor: Test

## 1. Komutlar

| Ne | Komut |
| --- | --- |
| Uygulama testleri | `flutter test` |
| Simülatör testleri | `cd tools/esp32_sim && dart test` |
| Analiz | `flutter analyze` (Windows'ta "ü" içeren yolda çökebilir; Docker kullanın) |
| Docker (hepsi) | `docker compose --profile test run --rm tests` |

## 2. Otomatik testler

### Uygulama (`test/`, 53 test)
| Dosya | Kapsam |
| --- | --- |
| `protocol_codec_test.dart` | telemetri çözümleme, bozuk JSON / NaN reddi, bilinmeyen tip, `sim_pose`, `pong`, rozet eşikleri |
| `motion_analyzer_test.dart` | ileri/geri/sağ/sol, statik, zayıf güven, 1 s'de kayıp, kayıpta mesafe sıçraması yok, ölçeksiz mesafe yok, eğimden toparlanma, sensör en/boy |
| `task_evaluator_test.dart` | A/B/C/E geçme ve kalma durumları, ölçek yokken KALDI, 2 s üstü kopma KALDI |
| `report_chain_test.dart` | deterministik hash, zincir bağlantısı, elle değiştirilen raporun yakalanması |
| `sim_glove_test.dart` | sanal eldiven adresi `/ws` → `/glove`, bağlantısız gönderim etkisiz; W A S D / boşluk doğru komutu gönderir; ekranda sürüş düğmesi yok (şartname 5.1) |
| `color_marker_test.dart` | YUV karede macenta işaret bulma, işaret yokken null, 90° döndürme |
| `frame_mapping_test.dart` | 1:1 / 9:16 cover kırpma, ekran↔sensör gidiş-dönüş |
| `widgets/screens_test.dart` | koptuğunda görev düğmesi kapalı; B'de yön seçilmeden devam yok; HUD varsayılan 1:1; 9:16'da şerit görüntü üstünde; **yön göstergesi sol kenarda, ≤ 72 px, dikey ortalı**; kayıp/görünür uyarısı |
| `widgets/navigation_test.dart` | Android geri tuşu: bağlantı → raporlar → geri; sonuç → geri / ✕ = panel ve kamera kapalı; sonuç → rapor → geri = sonuç; "Yeni test" → geri = panel; panelde geri → "Bağlantı kesilsin mi?" → Kes = bağlantı ekranı; kayıt sürerken geri engelli + uyarı |

### Simülatör (`tools/esp32_sim/test/`, 15 test)
- Model: `forward_moves_half_meter`, `right_turn_is_90_degrees`, `dock_then_charge_within_5s`,
  `telemetry_has_required_fields`
- Gerçekçi hareket: `accelerates_then_brakes`, `held_forward_drives_continuously_and_stop_brakes`,
  `battery_drains_faster_when_moving`
- Otomatik pilot: `task_B_forward_ends_near_one_meter`, `task_B_right_moves_sideways`,
  `task_C_and_E_end_charging`, `task_A_stays_still_30s`, `wander_stays_in_bounds_and_moves`,
  `glove_command_cancels_pilot`
- Sunucu: `glove_keys_map_to_commands` ve `server_end_to_end_hello_telemetry_glove`. Sonuncusu gerçek WebSocket üzerinden şunları dener:
hello, eldiven komutu → `moving` telemetrisi, ping/pong ve kontrol sayfası.

## 3. Robot olmadan uçtan uca deneme (simülatör)

**Elle (klavye):**
1. `docker compose up --build`
2. http://localhost:8080/?demo=B#/camera → **Testi başlat**
3. Aynı sekmede **W**'yi ~4 s basılı tut, bırak (kamera ekranında yön göstergesi "İleri" olur)
4. Beklenen: yön **İLERİ**, ~1,0 m, 2 s durunca otomatik bitiş, **GEÇTİ**

**Otomatik pilot (eline hiçbir şey almadan):** uygulamada görevi başlat, sonra
http://localhost:8765 → *Otomatik pilot* düğmesine bas. Eldivene basmak pilotu durdurur.

| Pilot / arıza düğmesi | Uygulamadaki görev | Beklenen sonuç |
| --- | --- | --- |
| A: 30 s denge (2 hafif itme) | `?demo=A` | GEÇTİ |
| B: 1 m İLERİ / GERİ / SOL / SAĞ | `?demo=B` + aynı yön | GEÇTİ; farklı yön seçilirse KALDI (yön) |
| C: istasyon + şarj (rastgele başlangıç) | `?demo=C` | GEÇTİ |
| E: bütünleşik (hedef → 5 s → şarj) | `?demo=E` | GEÇTİ |
| Kutuyu düşür (E sırasında) | E | KALDI (yük) |
| Serbest gezinti | herhangi | robot sürekli dolaşır; pil < %20 olunca şarja döner |
| İt / Devir | A | "toparlanma" / KALDI (denge) |
| 3 s kesinti | herhangi | rozet "Koptu", rapor "Bağlantı" KALDI |
| Kötü Wi-Fi (0–600 ms gecikme, %5 kayıp) | herhangi | rozet ara ara "Yavaş"; test yine sonuçlanır |
| Robotu gizle/göster | herhangi | "! Robot kayboldu"; mesafe sıçramaz |
| Pil %19 / %100 | panel | pil göstergesi; gezintide şarja dönüş |

Simülatör modeli: 1 m/s² hızlanma ve fren, 0,25 m/s hız, 90°/s dönüş. Eğim ivme ve hızla
değişir, durunca yavaş salınır. Pil beklerken %0,01/s, sürüşte %0,04/s azalır; şarjda %0,15/s dolar.

> 2026-10-16, Docker + Edge headless: B (uygulama sekmesinde W basılı) **GEÇTİ 4/4**, 1,04 m.
> E (otomatik pilot) **GEÇTİ 4/4**, hedefte 5,9 s bekleme, şarj başladı.

## 4. Android'de elle test

### 4a. Emülatör / telefon + simülatör
Simülatör: `cd tools/esp32_sim && dart run bin/esp32_sim.dart`. Uygulama: `flutter run -d emulator-5554`
(Android'i `subst` ile açılan `X:` sürücüsünden derlemeyin). Adres: emülatörde `ws://10.0.2.2:8765/ws`,
telefonda `ws://<bilgisayar IP>:8765/ws` (aynı Wi-Fi).

- [ ] 01: telefonda "Simülatör (localhost)" seçeneği yok, IP ipucu görünür
- [ ] 01 → Rapor geçmişi → **geri** = 01 (uygulama kapanmaz)
- [ ] 02'de **geri** → "Bağlantı kesilsin mi?"; Vazgeç = kalır, Kes = 01
- [ ] Robotu simülatör sayfasındaki sürüş pedinden (http://localhost:8765) ya da emülatör penceresinde W A S D ile sür; simülatör günlüğünde `Eldiven: forward` görünür
- [ ] 03 → 04 → 05; kayıt sürerken **geri** engelli ve "Kayıt sürerken çıkılamaz" uyarısı çıkar
- [ ] 05'te ekran kararmaz; telefon yatırılınca ekran dönmez
- [ ] 06: **geri** ve ✕ = 02; "Raporu aç" → **geri** = 06; "Yeni test" → **geri** = 02
- [ ] 07: "Dışa aktar / paylaş" Android paylaşım menüsünü açar (Drive, e-posta…)
- [ ] 06'dan çıkınca kamera bırakılır: `adb shell dumpsys media.camera` → açık istemci yok
- [ ] 05'te uygulama arka plana alınıp geri gelince görüntü yeniden açılır

### 4b. Gerçek robot

- [ ] Telefon `CDTP-ROBOT` ağında; 01'de üç doğrulama adımı da işaretli
- [ ] 02: paket hızı ≈ 1,0 Hz; robot kapatılınca 2 s içinde "Koptu"
- [ ] 04: zemindeki 1 m işaretin uçlarına dokununca ölçek görünür; robotta macenta işaret varken "Robot kadrajda" işaretlenir
- [ ] 04 / 05: kamera izni reddedilince hata + "Tekrar dene" görünür; izin verip "Tekrar dene" ile görüntü gelir
- [ ] 05: 1:1 / 4:3 / 9:16 değişimi; yön göstergesi solda; robot elle kadrajdan çıkarılınca "Robot kayboldu"
- [ ] 06: video kaydı oluştu (yol rapor detayında); "Kilitli" + SHA-256
- [ ] 07: "Bütünlüğü doğrula" → ✓ değişmemiş

## 5. Ö4 kontrol listesi (şartname 5×4)

| Ö4 alt testi | Nerede karşılanıyor | Durum |
| --- | --- | --- |
| 1 Hz şarj + eğim, canlı | 02 ana panel, 05 şerit; `RobotRepository` | ✓ simülatörde doğrulandı |
| Kameradan hareket ve yön tespiti | `MotionAnalyzer`, `ColorMarkerTracker` | ✓ simülatörde; gerçek kamera elle test edilecek |
| Göreve göre otomatik değerlendirme | `TaskRun` | ✓ birim testleri + uçtan uca B |
| Değiştirilemez rapor | `ReportRepository` + `ReportChain` | ✓ birim testi (elle değiştirme yakalanır) |
