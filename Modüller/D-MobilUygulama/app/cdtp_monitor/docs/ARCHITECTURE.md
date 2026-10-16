# cdtp_monitor: Mimari

## 1. Genel bakış

```
 Eldiven ESP32-S3 ──(ESP-NOW; simde ws:/glove)──► Robot ESP32-S3 ──(Wi-Fi WebSocket, JSON)──► Telefon (cdtp_monitor)
                                                       │  hello · telemetry 1 Hz · event · pong        │
                                                       │                                                ├─ kamera (renk işareti takibi)
                                                       └──── telefon: hello · ping 1 s · test start/stop┘
```

Uygulama robota **hareket komutu göndermez**; komutlar yalnız eldivenden gelir (şartname 5.1).
Tek istisna geliştirme içindir: **simülatöre** bağlıyken `SimGloveLayer` klavyeyi sanal
eldivene çevirir ve komutu ayrı `/glove` kanalına yollar (`SimGloveService`). Robot kanalı
`/ws`'ye hiçbir zaman komut gitmez; gerçek robota bağlıyken katman devre dışıdır.

## 2. Katmanlar (Flutter önerilen MVVM)

```
lib/
├── domain/            saf Dart: iş kuralları, Flutter UI'ına bağımlı değil
│   ├── models/        Telemetry, LinkState, TaskKind, TrackSample/MotionSnapshot, SceneSetup, Criterion, TestReport
│   └── use_cases/     MotionAnalyzer · TaskRun (değerlendirme) · ReportChain (SHA-256 zinciri)
├── data/
│   ├── services/      ProtocolCodec · RobotSocketService · ReportFileService (io/web) · tracker/*
│   └── repositories/  RobotRepository · TrackingRepository · ReportRepository
├── ui/
│   ├── core/          tema, biçimler, SessionStore, ortak widget'lar, CameraSurface + FrameMapping
│   └── features/<ekran>/{view_models,views}
├── app_scope.dart     InheritedWidget ile bağımlılıklar (harici DI paketi yok)
├── router.dart        go_router: wireframe akışı
└── dev_preset.dart    yalnız web: ?demo=B gibi önizleme ayarları
```

| Ekran | View | ViewModel / durum |
| --- | --- | --- |
| 01 Bağlantı | `connection_screen.dart` | `ConnectionViewModel` |
| 02 Ana panel | `dashboard_screen.dart` | `RobotRepository.link` + `latest` |
| 03 Görev seçimi | `task_select_screen.dart` | `SessionStore` |
| 04 Sahne | `scene_screen.dart` | `SceneViewModel` |
| 05 Kamera + HUD | `camera_hud_screen.dart` | `CameraHudViewModel` |
| 06 Sonuç | `result_screen.dart` | `ReportRepository.byId` |
| 07 Raporlar | `reports_screen.dart`, `report_detail_screen.dart` | `ReportRepository` |

## 3. Protokol (v1 uyumlu)

`cdtp_app/docs/PROTOCOL.md` ile aynıdır; ESP32-S3 firmware'i iki uygulamaya da hizmet eder.

| Yön | Mesaj | Not |
| --- | --- | --- |
| robot → telefon | `{"type":"hello","proto":1,"device":"CDTP-ROBOT"}` | bağlanınca |
| robot → telefon | `{"type":"telemetry","battery_pct":78.5,"tilt_deg":1.4,"charging":false, ...}` | **1 Hz**; isteğe bağlı: `docked`, `state`, `box_present`, `last_cmd` |
| robot → telefon | `{"type":"pong","id":42}` | sağlığı **etkilemez** (yalnız telemetri sayılır) |
| telefon → robot | `ping` (1 s), `hello`, `test start/stop` | |
| sim → telefon | `{"type":"sim_pose","x_m":0,"y_m":0.97,"heading_deg":0,"visible":true}` | **yalnız simülatör**, 10 Hz; gerçek robot göndermez |
| eldiven → robot | `{"type":"glove_cmd","cmd":"forward","seq":3}` | simde `ws://…/glove`; gerçek donanımda ESP-NOW önerilir |

Bağlantı rozeti: son *telemetri*den bu yana ≤ 1,5 s **bağlı**, 1,5–2 s **gecikme**, > 2 s **koptu**.
Kopmada 0,5 s aralıkla yeniden bağlanılır. Test boyunca en uzun boşluk (`maxGap`) ölçülür ve
"Bağlantı" ölçütü olarak rapora girer (≤ 2 s).

## 4. Kamera takibi

`MotionTracker` arayüzü iki kaynağa sahiptir; seçim `TrackingRepository.open()` içindedir:

| Kaynak | Ne zaman | Nasıl |
| --- | --- | --- |
| `SimTracker` | web (Docker) ya da simülatör adresi | `sim_pose` metre → sanal kamera: başlangıç (0,5; 0,8), 1 m = 0,25 birim |
| `ColorMarkerTracker` | Android + gerçek robot | arka kamera YUV420, ~10 Hz; **macenta işaret** (U, V > 150) ağırlık merkezi; güven = eşleşen oran / beklenen; test sırasında video kaydı da aynı akıştan |

**Robotun üstüne macenta (ya da yeşil, `MarkerColor.green`) bir işaret yapıştırılmalıdır.** Bu Modül A ve E ekipleriyle konuşulacak.

`MotionAnalyzer` (saf Dart, test edilir):
- Hız 0,5 s penceresinden hesaplanır. Hareket eşiği 0,05 m/s.
- Yön, hızın robotun önü (sahnede tanımlı, varsayılan "kameradan uzağa") ve dik eksen üzerine izdüşümüyle bulunur: İLERİ / GERİ / SAĞ / SOL / DURUYOR.
- `dönüyor` ve `toparlanma` durumları telemetriden gelir (`state`, |eğim| > 8°).
- Mesafe, görünür örnekler arası yolun piksel→metre ölçeğine bölünmesidir. Kayıp aralıktaki sıçrama sayılmaz.
- Takip güveni < %60 ise "zor görünüyor", 1 s örnek yoksa "kayboldu".

**Ölçek ve görüntü oranı:** Ölçüm koordinatları *sensör karesinde*dir. 1:1 / 4:3 / 9:16 seçimi
yalnız ekrandaki kırpmayı (`FrameMapping`, cover) değiştirir; mesafeyi etkilemez.

## 5. Değerlendirme (`TaskRun`)

| Görev | Ölçütler | Otomatik bitiş |
| --- | --- | --- |
| A Statik denge | süre 30 s ± 2 · hareket yok · düşmedi | 30 s ya da düşme |
| B Yönlendirme | yön = beklenen · mesafe 0,8–1,2 m · son konum durdu | ≥ 0,3 m sonra 2 s durağan |
| C Şarj | yerleşme (telemetri `docked` ya da hedef bölgede 1 s durağan) · şarj ≤ 5 s | şarj başladı ya da dock + 5 s |
| E Bütünleşik | kutu düşmedi (`box_present`) · hedefte ≥ 5 s · şarj başladı | şarj başladı |
| Hepsi | bağlantı boşluğu ≤ 2 s | |

Ölçülemeyen ölçüt **KALDI** sayılır (ör. ölçek yoksa mesafe). Ayrı bir "geçersiz" sonucu yoktur.

## 6. Raporlar

- `reports.jsonl` dosyasına yalnız ekleme yapılır; `ReportRepository`'de silme ya da güncelleme yöntemi yoktur.
- Her rapor `prev_hash` içerir. `hash = SHA-256(anahtarları sıralı JSON gövdesi)`.
- "Bütünlüğü doğrula" düğmesi dosyayı yeniden okur ve zinciri baştan kontrol eder.
- Dışa aktarma: JSON. PDF sonraki iştir.
- Web önizlemesinde raporlar bellekte tutulur.

## 7. Bilinen sınırlar
- Gerçek kamera takibi renk işaretine dayanır; ışık değişiminde eşik ayarı gerekebilir (`MarkerColor`).
- Video dosyasının SHA-256'sı henüz rapora eklenmiyor (yalnız yol).
- Kutu durumu kamerayla algılanmıyor. Robot `box_present` göndermezse E görevinde "Yük durumu" KALDI olur.
- 9:16'da alt şerit görüntünün alt bandını kapatır; robotu kadrajın ortasına yerleştirin.
- `flutter analyze`, proje yolundaki "ü" harfi yüzünden Windows'ta çökebilir (Dart LSP hatası). Docker içinde ya da ASCII bir yolda çalıştırın.
