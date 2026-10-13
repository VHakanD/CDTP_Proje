import 'package:flutter/material.dart';

/// Robot ile hangi kablosuz yoldan konusulacagi.
enum TransportKind {
  /// ESP32 SoftAP + WebSocket (birincil yol).
  wifi('Wi-Fi'),

  /// ESP32 BLE, Nordic UART Service uzerinden ayni JSON mesajlari (ikincil yol).
  ble('Bluetooth LE');

  const TransportKind(this.label);
  final String label;
}

/// Kullanicinin degistirebildigi tum ayarlar.
///
/// Degerlendirme esikleri sartnameden gelen varsayilanlarla baslar. Final testi
/// basladiktan sonra esikler degistirilmemelidir; bu yuzden her rapora o anki
/// esikler de yazilir (rapor kendi kendini aciklar).
@immutable
class AppSettings {
  const AppSettings({
    this.transport = TransportKind.wifi,
    this.wsHost = '192.168.4.1',
    this.wsPort = 80,
    this.wsPath = '/ws',
    this.bleNamePrefix = 'CDTP',
    this.themeMode = ThemeMode.system,
    this.recordVideo = true,
    this.thresholds = const EvaluationThresholds(),
  });

  final TransportKind transport;
  final String wsHost;
  final int wsPort;
  final String wsPath;
  final String bleNamePrefix;
  final ThemeMode themeMode;

  /// Test sirasinda telefon kamerasiyla video kaydi alinsin mi.
  final bool recordVideo;
  final EvaluationThresholds thresholds;

  Uri get wsUri => Uri(scheme: 'ws', host: wsHost, port: wsPort, path: wsPath);

  AppSettings copyWith({
    TransportKind? transport,
    String? wsHost,
    int? wsPort,
    String? wsPath,
    String? bleNamePrefix,
    ThemeMode? themeMode,
    bool? recordVideo,
    EvaluationThresholds? thresholds,
  }) =>
      AppSettings(
        transport: transport ?? this.transport,
        wsHost: wsHost ?? this.wsHost,
        wsPort: wsPort ?? this.wsPort,
        wsPath: wsPath ?? this.wsPath,
        bleNamePrefix: bleNamePrefix ?? this.bleNamePrefix,
        themeMode: themeMode ?? this.themeMode,
        recordVideo: recordVideo ?? this.recordVideo,
        thresholds: thresholds ?? this.thresholds,
      );

  Map<String, Object?> toJson() => {
        'transport': transport.name,
        'wsHost': wsHost,
        'wsPort': wsPort,
        'wsPath': wsPath,
        'bleNamePrefix': bleNamePrefix,
        'themeMode': themeMode.name,
        'recordVideo': recordVideo,
        'thresholds': thresholds.toJson(),
      };

  factory AppSettings.fromJson(Map<String, Object?> j) {
    const d = AppSettings();
    return AppSettings(
      transport: TransportKind.values.asNameMap()[j['transport']] ?? d.transport,
      wsHost: j['wsHost'] as String? ?? d.wsHost,
      wsPort: (j['wsPort'] as num?)?.toInt() ?? d.wsPort,
      wsPath: j['wsPath'] as String? ?? d.wsPath,
      bleNamePrefix: j['bleNamePrefix'] as String? ?? d.bleNamePrefix,
      themeMode: ThemeMode.values.asNameMap()[j['themeMode']] ?? d.themeMode,
      recordVideo: j['recordVideo'] as bool? ?? d.recordVideo,
      thresholds: j['thresholds'] is Map
          ? EvaluationThresholds.fromJson((j['thresholds'] as Map).cast<String, Object?>())
          : d.thresholds,
    );
  }
}

/// Otomatik gecti/kaldi kararinda kullanilan esikler (sartname 5.2 ve 8).
@immutable
class EvaluationThresholds {
  const EvaluationThresholds({
    this.staticBalanceSeconds = 30,
    this.timeToleranceSeconds = 2,
    this.distanceMinM = 0.8,
    this.distanceMaxM = 1.2,
    this.chargeStartWindowSeconds = 5,
    this.initialBalanceSeconds = 5,
    this.targetWaitSeconds = 5,
    this.fallTiltDeg = 35,
    this.staticMaxDisplacementM = 0.10,
    this.maxLinkGapSeconds = 2,
    this.guidanceTimeoutSeconds = 60,
    this.chargingTimeoutSeconds = 60,
    this.integratedTimeoutSeconds = 300,
    this.turnTargetDeg = 90,
    this.turnToleranceDeg = 30,
  });

  /// Statik denge suresi (Modul A: 30 s).
  final double staticBalanceSeconds;

  /// Uygulamanin olctugu sure icin kabul edilen tolerans (sartname: ±2 s).
  final double timeToleranceSeconds;

  /// Yonlendirme gorevinde kat edilmesi gereken mesafe araligi (0,8–1,2 m).
  final double distanceMinM;
  final double distanceMaxM;

  /// Yerlesmeden sonra sarjin baslamasi icin izin verilen sure (5 s).
  final double chargeStartWindowSeconds;

  /// Butunlesik gorevin basinda dengede bekleme suresi (5 s).
  final double initialBalanceSeconds;

  /// Butunlesik gorevde hedefte bekleme suresi (5 s).
  final double targetWaitSeconds;

  /// Bu acinin uzerindeki egim "dustu" kabul edilir.
  final double fallTiltDeg;

  /// Statik denge sirasinda kamerada izin verilen en buyuk yer degistirme.
  final double staticMaxDisplacementM;

  /// Telemetride izin verilen en uzun bosluk (sartname: 2 s).
  final double maxLinkGapSeconds;

  /// Gorevler icin otomatik bitirme (zaman asimi) sureleri.
  final double guidanceTimeoutSeconds;
  final double chargingTimeoutSeconds;
  final double integratedTimeoutSeconds;

  /// Donus komutunda beklenen aci (yaklasik 90°) ve kabul edilen sapma.
  final double turnTargetDeg;
  final double turnToleranceDeg;

  EvaluationThresholds copyWith({
    double? staticBalanceSeconds,
    double? timeToleranceSeconds,
    double? distanceMinM,
    double? distanceMaxM,
    double? chargeStartWindowSeconds,
    double? initialBalanceSeconds,
    double? targetWaitSeconds,
    double? fallTiltDeg,
    double? staticMaxDisplacementM,
    double? maxLinkGapSeconds,
    double? guidanceTimeoutSeconds,
    double? chargingTimeoutSeconds,
    double? integratedTimeoutSeconds,
    double? turnTargetDeg,
    double? turnToleranceDeg,
  }) =>
      EvaluationThresholds(
        staticBalanceSeconds: staticBalanceSeconds ?? this.staticBalanceSeconds,
        timeToleranceSeconds: timeToleranceSeconds ?? this.timeToleranceSeconds,
        distanceMinM: distanceMinM ?? this.distanceMinM,
        distanceMaxM: distanceMaxM ?? this.distanceMaxM,
        chargeStartWindowSeconds: chargeStartWindowSeconds ?? this.chargeStartWindowSeconds,
        initialBalanceSeconds: initialBalanceSeconds ?? this.initialBalanceSeconds,
        targetWaitSeconds: targetWaitSeconds ?? this.targetWaitSeconds,
        fallTiltDeg: fallTiltDeg ?? this.fallTiltDeg,
        staticMaxDisplacementM: staticMaxDisplacementM ?? this.staticMaxDisplacementM,
        maxLinkGapSeconds: maxLinkGapSeconds ?? this.maxLinkGapSeconds,
        guidanceTimeoutSeconds: guidanceTimeoutSeconds ?? this.guidanceTimeoutSeconds,
        chargingTimeoutSeconds: chargingTimeoutSeconds ?? this.chargingTimeoutSeconds,
        integratedTimeoutSeconds: integratedTimeoutSeconds ?? this.integratedTimeoutSeconds,
        turnTargetDeg: turnTargetDeg ?? this.turnTargetDeg,
        turnToleranceDeg: turnToleranceDeg ?? this.turnToleranceDeg,
      );

  Map<String, Object?> toJson() => {
        'staticBalanceSeconds': staticBalanceSeconds,
        'timeToleranceSeconds': timeToleranceSeconds,
        'distanceMinM': distanceMinM,
        'distanceMaxM': distanceMaxM,
        'chargeStartWindowSeconds': chargeStartWindowSeconds,
        'initialBalanceSeconds': initialBalanceSeconds,
        'targetWaitSeconds': targetWaitSeconds,
        'fallTiltDeg': fallTiltDeg,
        'staticMaxDisplacementM': staticMaxDisplacementM,
        'maxLinkGapSeconds': maxLinkGapSeconds,
        'guidanceTimeoutSeconds': guidanceTimeoutSeconds,
        'chargingTimeoutSeconds': chargingTimeoutSeconds,
        'integratedTimeoutSeconds': integratedTimeoutSeconds,
        'turnTargetDeg': turnTargetDeg,
        'turnToleranceDeg': turnToleranceDeg,
      };

  factory EvaluationThresholds.fromJson(Map<String, Object?> j) {
    const d = EvaluationThresholds();
    double v(String k, double def) => (j[k] as num?)?.toDouble() ?? def;
    return EvaluationThresholds(
      staticBalanceSeconds: v('staticBalanceSeconds', d.staticBalanceSeconds),
      timeToleranceSeconds: v('timeToleranceSeconds', d.timeToleranceSeconds),
      distanceMinM: v('distanceMinM', d.distanceMinM),
      distanceMaxM: v('distanceMaxM', d.distanceMaxM),
      chargeStartWindowSeconds: v('chargeStartWindowSeconds', d.chargeStartWindowSeconds),
      initialBalanceSeconds: v('initialBalanceSeconds', d.initialBalanceSeconds),
      targetWaitSeconds: v('targetWaitSeconds', d.targetWaitSeconds),
      fallTiltDeg: v('fallTiltDeg', d.fallTiltDeg),
      staticMaxDisplacementM: v('staticMaxDisplacementM', d.staticMaxDisplacementM),
      maxLinkGapSeconds: v('maxLinkGapSeconds', d.maxLinkGapSeconds),
      guidanceTimeoutSeconds: v('guidanceTimeoutSeconds', d.guidanceTimeoutSeconds),
      chargingTimeoutSeconds: v('chargingTimeoutSeconds', d.chargingTimeoutSeconds),
      integratedTimeoutSeconds: v('integratedTimeoutSeconds', d.integratedTimeoutSeconds),
      turnTargetDeg: v('turnTargetDeg', d.turnTargetDeg),
      turnToleranceDeg: v('turnToleranceDeg', d.turnToleranceDeg),
    );
  }
}
