/// Bağlantı rozeti seviyeleri (wireframe 02).
enum LinkLevel { disconnected, connecting, ok, slow, lost }

/// Rozet eşikleri. Şartname yalnız 2 s'yi zorunlu tutar; 1,5 s ekip seçimi.
abstract final class LinkHealth {
  static const okLimit = Duration(milliseconds: 1500);
  static const lostLimit = Duration(seconds: 2);

  /// Son *telemetri* paketinden bu yana geçen süreye göre seviye.
  /// `pong` gibi diğer mesajlar bu süreyi sıfırlamaz.
  static LinkLevel levelFor(Duration sinceTelemetry, {required bool socketOpen}) {
    if (!socketOpen) return LinkLevel.disconnected;
    if (sinceTelemetry <= okLimit) return LinkLevel.ok;
    if (sinceTelemetry <= lostLimit) return LinkLevel.slow;
    return LinkLevel.lost;
  }
}

/// Arayüzün okuduğu anlık bağlantı durumu.
class LinkState {
  const LinkState({
    required this.level,
    this.sinceLastTelemetry,
    this.hz = 0,
    this.maxGap = Duration.zero,
    this.uri,
    this.device,
    this.error,
    this.helloReceived = false,
    this.telemetryReceived = false,
  });

  static const initial = LinkState(level: LinkLevel.disconnected);

  final LinkLevel level;
  final Duration? sinceLastTelemetry;
  final double hz;

  /// `resetGap()` çağrısından bu yana en uzun telemetri boşluğu.
  final Duration maxGap;
  final Uri? uri;
  final String? device;
  final String? error;
  final bool helloReceived;
  final bool telemetryReceived;

  bool get usable => level == LinkLevel.ok || level == LinkLevel.slow;

  LinkState copyWith({
    LinkLevel? level,
    Duration? sinceLastTelemetry,
    double? hz,
    Duration? maxGap,
    Uri? uri,
    String? device,
    String? error,
    bool clearError = false,
    bool? helloReceived,
    bool? telemetryReceived,
  }) =>
      LinkState(
        level: level ?? this.level,
        sinceLastTelemetry: sinceLastTelemetry ?? this.sinceLastTelemetry,
        hz: hz ?? this.hz,
        maxGap: maxGap ?? this.maxGap,
        uri: uri ?? this.uri,
        device: device ?? this.device,
        error: clearError ? null : (error ?? this.error),
        helloReceived: helloReceived ?? this.helloReceived,
        telemetryReceived: telemetryReceived ?? this.telemetryReceived,
      );
}
