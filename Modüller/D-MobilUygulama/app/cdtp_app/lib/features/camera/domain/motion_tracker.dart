import 'package:camera/camera.dart';

import 'motion_sample.dart';

/// Kamera goruntusunden robotun hareketini tespit eden bilesenin arayuzu.
///
/// DURUM: Yontem ekipce henuz secilmedi (renkli isaretci, ArUco, ML Kit ...).
/// Secim yapildiginda bu arayuzu uygulayan yeni bir sinif yazilir ve
/// `motionTrackerProvider` icinde PlaceholderMotionTracker yerine verilir.
/// Uygulamanin geri kalani (canli ekran, degerlendirme, rapor) degismez.
///
/// Beklenen davranis:
///  1. start() ile test basinda baslatilir; ilk konum (0,0) kabul edilir.
///  2. processFrame() her kamera karesiyle cagrilir (video kaydi surerken).
///  3. Her islenen kare/pencere icin [samples] akisina bir MotionSample yayinlanir.
///  4. stop() ile test sonunda durdurulur.
abstract class MotionTracker {
  /// Arayuzde gosterilen yontem adi.
  String get name;

  /// false ise tespit yoktur; arayuz "—" gosterir, ilgili kriterler "veri yok" olur.
  bool get isImplemented;

  /// Kamera karelerine ihtiyac duyuyor mu (false ise kare akisi acilmaz).
  bool get needsFrames;

  Stream<MotionSample> get samples;

  Future<void> start();

  void processFrame(CameraImage image);

  Future<void> stop();

  Future<void> dispose();
}
