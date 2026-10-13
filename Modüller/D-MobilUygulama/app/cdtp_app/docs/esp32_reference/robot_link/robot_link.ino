/*
 * CDTP Robot - Uygulama baglantisi REFERANS kodu (ESP32, Arduino)
 * ----------------------------------------------------------------
 * Bu dosya mobil uygulamanin bekledigi ag tarafini gosterir (protokol v1,
 * docs/PROTOCOL.md). Denge/motor/sarj kodu burada YOKTUR; elektronik ve
 * kontrol ekibi kendi kodlarina bu kismi ekler.
 *
 * Gerekli kutuphaneler (Arduino Library Manager):
 *   - ESPAsyncWebServer + AsyncTCP  (ESP32Async)
 *   - ArduinoJson (v7)
 *
 * Calisma:
 *   1) ESP32 "CDTP-ROBOT" adinda Wi-Fi agi (SoftAP) acar, IP: 192.168.4.1
 *   2) ws://192.168.4.1/ws adresinde WebSocket sunucusu calisir (port 80)
 *   3) Bagli tum istemcilere 1 Hz telemetri JSON'u gonderilir
 *   4) Uygulamanin "ping" mesajina "pong" ile cevap verilir
 *
 * ONEMLI: Denge dongusunu ASLA ag islemleriyle bloklamayin. Wi-Fi cekirdek 0'da
 * calisir; denge dongusunu cekirdek 1'de ayri bir gorevde (xTaskCreatePinnedToCore)
 * calistirmaniz onerilir.
 */

#include <WiFi.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoJson.h>

// ---------------- Ag ayarlari ----------------
static const char *AP_SSID = "CDTP-ROBOT";
static const char *AP_PASS = "cdtp2026";  // en az 8 karakter
static const uint32_t TELEMETRY_PERIOD_MS = 1000;  // sartname: 1 Hz

// ---------------- Pinler (ornek) ----------------
static const int PIN_CHG_STAT = 34;  // sarj entegresinin CHG/STAT cikisi (genelde aktif-dusuk)

AsyncWebServer server(80);
AsyncWebSocket ws("/ws");

uint32_t telemetrySeq = 0;
const char *lastCmd = nullptr;  // eldivenden gelen son komut
uint32_t lastCmdSeq = 0;

// =====================================================================
// SENSOR OKUMALARI - ekip kendi donanimina gore dolduracak
// =====================================================================

// Pil yuzdesi (0-100). Ornek: gerilim bolucu + ADC + bataryaya ozel egri.
float readBatteryPercent() { return NAN; }  // TODO

// Pil gerilimi (V). Opsiyonel.
float readBatteryVoltage() { return NAN; }  // TODO

// Govde egimi (derece). Denge kontrolcusunun kullandigi kestirilmis aci.
float readTiltDeg() { return NAN; }  // TODO

// Donanimsal sarj sinyali. Gosterge ile AYNI sinyal okunmali (yazilimla uretilmez).
bool readCharging() { return digitalRead(PIN_CHG_STAT) == LOW; }

// Robot istasyona yerlesti mi (orn. temas pedi gerilimi, limit switch). Opsiyonel.
bool readDocked() { return false; }  // TODO

// Ilac kutusu yerinde mi (orn. limit switch / IR). Opsiyonel.
bool readBoxPresent() { return true; }  // TODO

// IR istasyon sinyali algilaniyor mu. Opsiyonel.
bool readIrDetected() { return false; }  // TODO

// Robotun durum makinesi: idle|balancing|moving|turning|recovering|docking|docked|fallen
const char *readRobotState() { return "balancing"; }  // TODO

// =====================================================================

/// Eldiven alicisi bir komut cozdugunde cagirin: "forward","backward","left","right","stop"
void onGloveCommand(const char *cmd) {
  lastCmd = cmd;
  lastCmdSeq++;
  JsonDocument ev;
  ev["type"] = "event";
  ev["name"] = "glove_command";
  ev["value"] = cmd;
  ev["uptime_ms"] = millis();
  String out;
  serializeJson(ev, out);
  ws.textAll(out);
}

static void putIfValid(JsonDocument &doc, const char *key, float v, int decimals) {
  if (!isnan(v)) doc[key] = serialized(String(v, decimals));
}

void sendTelemetry() {
  JsonDocument doc;
  doc["type"] = "telemetry";
  doc["seq"] = telemetrySeq++;
  doc["uptime_ms"] = millis();
  // Zorunlu alanlar
  putIfValid(doc, "battery_pct", readBatteryPercent(), 1);
  putIfValid(doc, "tilt_deg", readTiltDeg(), 2);
  doc["charging"] = readCharging();
  // Opsiyonel alanlar (sensor yoksa bu satirlari silin)
  putIfValid(doc, "battery_v", readBatteryVoltage(), 2);
  doc["docked"] = readDocked();
  doc["state"] = readRobotState();
  doc["box_present"] = readBoxPresent();
  doc["ir_detected"] = readIrDetected();
  if (lastCmd != nullptr) {
    doc["last_cmd"] = lastCmd;
    doc["last_cmd_seq"] = lastCmdSeq;
  }
  String out;
  serializeJson(doc, out);
  ws.textAll(out);
}

void onWsEvent(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type,
               void *arg, uint8_t *data, size_t len) {
  if (type == WS_EVT_CONNECT) {
    // Baglanan uygulamaya robot kendini tanitir.
    JsonDocument hello;
    hello["type"] = "hello";
    hello["proto"] = 1;
    hello["device"] = "CDTP-ROBOT";
    hello["fw"] = "0.1.0";
    String out;
    serializeJson(hello, out);
    client->text(out);
    return;
  }
  if (type != WS_EVT_DATA) return;

  AwsFrameInfo *info = (AwsFrameInfo *)arg;
  // Sadece tek parcali metin cerceveleri (uygulamanin mesajlari kucuktur).
  if (!(info->final && info->index == 0 && info->len == len && info->opcode == WS_TEXT)) return;

  JsonDocument msg;
  if (deserializeJson(msg, data, len)) return;
  const char *t = msg["type"];
  if (t == nullptr) return;

  if (strcmp(t, "ping") == 0) {
    JsonDocument pong;
    pong["type"] = "pong";
    pong["id"] = msg["id"];
    String out;
    serializeJson(pong, out);
    client->text(out);
  } else if (strcmp(t, "test") == 0) {
    // Uygulama test basladi/bitti bilgisini gonderir. Istege bagli: seri porta yaz.
    Serial.printf("[app] test %s %s\n", (const char *)msg["action"], (const char *)msg["task"]);
  }
  // Not: Sartname geregi uygulama robota hareket komutu GONDERMEZ.
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_CHG_STAT, INPUT_PULLUP);

  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);
  WiFi.setSleep(false);  // gecikmeyi azaltir
  Serial.printf("AP: %s  IP: %s\n", AP_SSID, WiFi.softAPIP().toString().c_str());

  ws.onEvent(onWsEvent);
  server.addHandler(&ws);
  server.begin();
}

void loop() {
  static uint32_t lastSend = 0;
  uint32_t now = millis();
  if (now - lastSend >= TELEMETRY_PERIOD_MS) {
    lastSend = now;
    sendTelemetry();
    ws.cleanupClients();
  }
}
