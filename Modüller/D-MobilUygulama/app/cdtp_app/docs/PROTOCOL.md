# Robot ↔ Uygulama Ağ Protokolü (v1)

Bu belge mobil uygulamanın robotla (ESP32) nasıl konuştuğunu tanımlar. Elektronik ve
Haberleşme ekibi robot tarafını bu belgeye göre yazar. Örnek kod:
[esp32_reference/robot_link/robot_link.ino](esp32_reference/robot_link/robot_link.ino).

## 1. Bağlantı topolojisi

### Birincil yol: Wi-Fi + WebSocket (önerilen)

```
 ┌──────────────┐   Wi-Fi (SoftAP "CDTP-ROBOT")   ┌──────────────────────┐
 │  Telefon     │ ──────────────────────────────▶ │  ESP32 (robot)       │
 │  uygulama    │   ws://192.168.4.1:80/ws        │  WebSocket sunucusu  │
 └──────────────┘ ◀────── JSON, 1 Hz ──────────── └──────────────────────┘
```

| Ayar | Değer |
|---|---|
| Wi-Fi adı (SSID) | `CDTP-ROBOT` |
| Şifre | `cdtp2026` (en az 8 karakter, ekip değiştirebilir) |
| Robot IP | `192.168.4.1` (SoftAP varsayılanı) |
| Adres | `ws://192.168.4.1:80/ws` |
| Mesaj | UTF-8 JSON, her WebSocket metin çerçevesi = 1 mesaj |

Neden SoftAP: Final alanında internet / modem garantisi yok; robotun kendi ağı her yerde
aynı IP ile çalışır, telefon başka bir şeye bağımlı olmaz.

Alternatif (gerekirse): Telefon hotspot açar, ESP32 istasyon (STA) olarak bağlanır ve
**sabit IP** alır (örn. `192.168.43.50`). Uygulamada sadece adres değişir.

### İkincil yol: Bluetooth LE (Nordic UART Service)

Wi-Fi ile **aynı JSON mesajları**, her mesajın sonuna `\n` eklenerek gönderilir
(BLE paketleri 20–244 bayta bölünebildiği için uygulama satır sonuyla birleştirir).

| Öğe | UUID |
|---|---|
| Servis | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` |
| RX (uygulama → robot, write) | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` |
| TX (robot → uygulama, notify) | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` |
| Reklam adı | `CDTP` ile başlamalı (uygulamada ayarlanabilir) |

Uygulama tarafı: [ble_uart_link.dart](../lib/features/connection/data/ble_uart_link.dart).
Web tarayıcıda BLE yoktur; sadece Android/iOS.

## 2. Robot → Uygulama mesajları

### 2.1 `hello` (bağlantı kurulunca bir kez)

```json
{"type":"hello","proto":1,"device":"CDTP-ROBOT","fw":"0.1.0"}
```

### 2.2 `telemetry` (1 Hz, şartname 5.2)

```json
{
  "type": "telemetry",
  "seq": 128,
  "uptime_ms": 128450,
  "battery_pct": 78.5,
  "tilt_deg": 1.42,
  "charging": false,
  "battery_v": 11.82,
  "docked": false,
  "state": "balancing",
  "box_present": true,
  "ir_detected": false,
  "last_cmd": "forward",
  "last_cmd_seq": 7
}
```

| Alan | Tip | Zorunlu | Birim / değerler | Kaynak (robotta) | Uygulamada kullanım |
|---|---|---|---|---|---|
| `type` | string | evet | `"telemetry"` | – | – |
| `battery_pct` | sayı | **evet** | 0–100 % | ADC + pil eğrisi | Panel, şarj görevi |
| `tilt_deg` | sayı | **evet** | derece, + ileri | IMU kestirimi | Panel, düşme tespiti, tüm görevler |
| `charging` | bool | **evet** | CHG/STAT sinyali | Şarj entegresi pini | Şarj görevi (5 s kuralı) |
| `seq` | int | önerilir | artan sayaç | – | Kayıp paket analizi |
| `uptime_ms` | int | önerilir | ms | `millis()` | Rapor |
| `battery_v` | sayı | hayır | V | ADC | Panel |
| `docked` | bool | hayır | istasyonda mı | temas pedi / switch | Şarj görevi: yerleşme anı |
| `state` | string | hayır | `idle`, `balancing`, `moving`, `turning`, `recovering`, `docking`, `docked`, `fallen` | durum makinesi | Panel, hedefte bekleme, düşme |
| `box_present` | bool | hayır | kutu yerinde mi | limit switch / IR | Bütünleşik görev: kutu düştü mü |
| `ir_detected` | bool | hayır | istasyon IR görüyor mu | IR alıcı | Panel |
| `last_cmd` | string | hayır | `forward`, `backward`, `left`, `right`, `stop` | eldiven alıcısı | Yönlendirme raporu (bilgi) |
| `last_cmd_seq` | int | hayır | komut sayacı | – | Panel |

Kurallar:
- Opsiyonel bir sensör yoksa alanı **hiç göndermeyin** (uygulama "—" / "Veri yok" gösterir).
- Bilinmeyen alanlar yok sayılır; ekip yeni alan ekleyebilir.
- `charging` **donanımsal** şarj sinyalinden okunmalıdır (şartname 4.3).
- `docked` gönderilmezse şarj görevinde yerleşme anı kameradan alınır (kamera modülü
  tamamlanana kadar "Veri yok").

### 2.3 `event` (anlık, opsiyonel)

```json
{"type":"event","name":"glove_command","value":"left","uptime_ms":130020}
```

### 2.4 `pong` (uygulamanın `ping`ine cevap)

```json
{"type":"pong","id":42}
```

## 3. Uygulama → Robot mesajları

| Mesaj | Ne zaman | Robot ne yapar |
|---|---|---|
| `{"type":"hello","proto":1,"client":"cdtp-app","app_version":"0.1.0"}` | Bağlanınca | Yok sayabilir |
| `{"type":"ping","id":42}` | Her 1 s | `pong` ile aynı `id`yi döner (RTT ölçümü) |
| `{"type":"test","action":"start","task":"staticBalance","test_id":"T2026..."}` | Testi Başlat / Bitir | Yok sayabilir veya loglar |

**Uygulama robota hareket komutu göndermez.** Şartname 5.1: kabul testinde komutlar yalnız
eldivenden gelir; telefondan manuel komut kullanılamaz.

## 4. Zamanlama ve güvenilirlik (şartname 5.2)

| Gereksinim | Uygulamadaki karşılığı |
|---|---|
| Şarj + eğim 1 Hz | Robot her 1000 ms'de `telemetry` gönderir; uygulama son 10 s'de frekansı ölçer (Bağlantı sayfası) |
| Kopma ≤ 2 s | Watchdog her 250 ms kontrol eder; 2 s veri gelmezse durum **"Veri gelmiyor"** olur, olay günlüğüne yazılır |
| Kopunca | Uygulama 0,5 s aralıkla otomatik yeniden bağlanır |
| Test kaydı | Her testte en uzun telemetri boşluğu ölçülür; > 2 s ise "Bağlantı sürekliliği" kriteri **KALDI** |

Kod: [robot_connection_controller.dart](../lib/features/connection/application/robot_connection_controller.dart).

## 5. Robota bağlanma adımları

1. Robotu açın; seri monitörde `AP: CDTP-ROBOT IP: 192.168.4.1` görülmeli.
2. Telefon **Ayarlar > Wi-Fi** → `CDTP-ROBOT` ağına bağlanın.
3. Android "Bu ağda internet yok" uyarısı verirse **"Bağlı kal / Yine de bağlan"** seçin.
4. **Mobil veriyi kapatın** (bazı telefonlar internetsiz Wi-Fi yerine mobil veriyi kullanır).
5. Uygulama → **Bağlantı** → yol: Wi-Fi → **ESP32 SoftAP** hazır ayarı → **Bağlan**.
6. Durum **Bağlı**, frekans ≈ **1,0 Hz**, olay günlüğünde `Robot: CDTP-ROBOT ...` görülmeli.

## 6. Sorun giderme

| Belirti | Olası neden / çözüm |
|---|---|
| "Bağlanamadı: TimeoutException" | Telefon robot ağında değil; IP/port/yol yanlış; ESP32'de `/ws` handler eklenmemiş |
| Bağlanıyor ama veri yok | ESP32 `ws.textAll` çağırmıyor; JSON'da `"type":"telemetry"` eksik |
| "Çözülemeyen mesaj" sayısı artıyor | JSON bozuk (fazladan virgül, NaN). `NaN` JSON değildir: sensör yoksa alanı göndermeyin |
| Frekans 1 Hz'in altında | Ana döngü bloklanıyor; telemetriyi denge döngüsünden ayırın |
| Sık "Veri gelmiyor" | Wi-Fi güç tasarrufu: `WiFi.setSleep(false)`; anten/gövde konumu |
| Release APK bağlanmıyor, debug bağlanıyor | `AndroidManifest.xml`de `INTERNET` ve `usesCleartextTraffic="true"` olmalı (projede var) |
| BLE cihaz bulunamadı | Reklam adı `CDTP` ile başlamıyor; Android'de Bluetooth/Yakındaki cihazlar izni verilmedi |

## 7. Uyumluluk

`proto` alanı protokol sürümüdür. Uyumsuz bir değişiklik yapılırsa robot ve uygulamada
birlikte artırılır ([app_constants.dart](../lib/core/config/app_constants.dart)
`protocolVersion`). Uygulama farklı sürüm görürse olay günlüğüne uyarı yazar.
