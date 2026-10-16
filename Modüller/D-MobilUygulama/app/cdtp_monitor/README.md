# cdtp_monitor: wireframe uyumlu robot izleme uygulaması

Modül D'nin ikinci uygulaması. `cdtp_app`'in yanında durur ve ondan bağımsızdır. Ekranlar
`docs/wireframes/` ve [html/index.html](../../docs/wireframes/html/index.html) ile birebir eşleşir:

| # | Ekran | Rota |
| --- | --- | --- |
| 01 | Bağlantı (ESP32-S3, Wi-Fi WebSocket) | `/connect` |
| 02 | Ana panel / canlı sensör | `/dashboard` |
| 03 | Görev seçimi | `/tasks` |
| 04 | Sahne hazırlama (ölçek, hedef bölge) | `/scene` |
| 05 | Kamera + HUD, Varyant B (yön sol kenarda; 1:1 / 4:3 / 9:16) | `/camera` |
| 06 | Sonuç (GEÇTİ / KALDI, mühür) | `/result/:id` |
| 07 | Rapor geçmişi + detay | `/reports`, `/reports/:id` |

## Hızlı başlangıç (Docker, robot gerekmez)

```sh
docker compose up --build
```

İki container çalışır; **robotu 8765'ten ya da uygulama sekmesinde klavyeyle sürersin**:

| Adres | Container | Ne |
| --- | --- | --- |
| http://localhost:8080 | `app` | Uygulama (yalnız izler). Simülatöre bağlıyken **W A S D / oklar = sanal eldiven** |
| http://localhost:8080/?demo=B#/camera | `app` | Hazır demo: Görev B, simülatöre bağlı, kamera ekranı (`demo=A/C/E` de olur) |
| http://localhost:8765 | `sim` | Robot + eldiven simülatörü: sürüş pedi, **otomatik pilot**, arıza düğmeleri |

Kısa bas = 0,5 m / 90° adım; basılı tut = sürekli sür, bırak = fren.

Testler: `docker compose --profile test run --rm tests`

## Docker olmadan
```sh
flutter pub get
cd tools/esp32_sim && dart pub get && dart run bin/esp32_sim.dart   # robot simülatörü
flutter run -d chrome    # ya da: flutter run -d emulator-5554 (Android)
```
Simülatör adresi uygulamanın nerede çalıştığına göre değişir:

| Uygulama | Simülatör adresi |
| --- | --- |
| Tarayıcı (aynı bilgisayar) | `ws://localhost:8765/ws` |
| Android emülatörü | `ws://10.0.2.2:8765/ws` (hazır seçenek) |
| Gerçek telefon | `ws://<bilgisayar IP>:8765/ws`; telefon ve bilgisayar aynı Wi-Fi'de |

Uygulamada ekran üstü sürüş düğmesi yoktur (şartname 5.1: komutlar yalnız eldivenden). Robotu
simülatör sayfasındaki sürüş pedinden (http://localhost:8765) ya da emülatör penceresinde
W A S D ile sürün. Uygulama dikey kilitlidir ve kamera ekranında ekran kararmaz. Rapor detayındaki
"Dışa aktar / paylaş" JSON'u Android paylaşım menüsüyle gönderir.

Android telefonda gerçek robot için: telefonu `CDTP-ROBOT` Wi-Fi ağına bağlayın ve
`ws://192.168.4.1:80/ws` adresini seçin. Elle test listesi: [docs/TESTING.md](docs/TESTING.md) §4.

## Belgeler
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): katmanlar, veri akışı, protokol, kamera takibi
- [docs/TESTING.md](docs/TESTING.md): test listesi, simülatör senaryoları, Ö4 kontrol listesi
- Plan: [../../docs/plans/2026-10-15-cdtp-monitor.md](../../docs/plans/2026-10-15-cdtp-monitor.md)
