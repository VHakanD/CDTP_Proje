import 'package:flutter/foundation.dart';

import '../../settings/domain/app_settings.dart';
import 'robot_telemetry.dart';

/// Arayuzde gosterilen baglanti durumu.
enum LinkPhase {
  disconnected('Bağlı değil'),
  connecting('Bağlanıyor'),
  connected('Bağlı'),

  /// Kanal acik ama 2 s'den uzun suredir veri gelmiyor (sartname ihlali).
  stale('Veri gelmiyor');

  const LinkPhase(this.label);
  final String label;
}

/// Robotun "hello" mesajinda bildirdigi bilgiler.
@immutable
class RobotInfo {
  const RobotInfo({required this.device, required this.firmware, required this.protocol});
  final String device;
  final String firmware;
  final int protocol;
}

/// Baglanti kalitesi istatistikleri (sartname: 1 Hz, kopma <= 2 s).
@immutable
class LinkStats {
  const LinkStats({
    this.connectedAt,
    this.lastRxAt,
    this.telemetryCount = 0,
    this.parseErrors = 0,
    this.maxGapMs = 0,
    this.gapViolations = 0,
    this.reconnects = 0,
    this.measuredHz,
    this.rttMs,
  });

  final DateTime? connectedAt;
  final DateTime? lastRxAt;
  final int telemetryCount;
  final int parseErrors;

  /// Bu baglanti boyunca iki mesaj arasindaki en uzun sure.
  final int maxGapMs;

  /// 2 s sinirini asan bosluk sayisi.
  final int gapViolations;
  final int reconnects;

  /// Son 10 s'de olculen telemetri frekansi.
  final double? measuredHz;

  /// Son ping-pong gidis-donus suresi.
  final int? rttMs;

  LinkStats copyWith({
    DateTime? connectedAt,
    DateTime? lastRxAt,
    int? telemetryCount,
    int? parseErrors,
    int? maxGapMs,
    int? gapViolations,
    int? reconnects,
    double? measuredHz,
    int? rttMs,
  }) =>
      LinkStats(
        connectedAt: connectedAt ?? this.connectedAt,
        lastRxAt: lastRxAt ?? this.lastRxAt,
        telemetryCount: telemetryCount ?? this.telemetryCount,
        parseErrors: parseErrors ?? this.parseErrors,
        maxGapMs: maxGapMs ?? this.maxGapMs,
        gapViolations: gapViolations ?? this.gapViolations,
        reconnects: reconnects ?? this.reconnects,
        measuredHz: measuredHz ?? this.measuredHz,
        rttMs: rttMs ?? this.rttMs,
      );
}

enum LinkEventLevel { info, warning, error }

/// Baglanti sayfasindaki olay gunlugu satiri.
@immutable
class LinkEvent {
  const LinkEvent(this.time, this.message, [this.level = LinkEventLevel.info]);
  final DateTime time;
  final String message;
  final LinkEventLevel level;
}

/// Baglanti modulunun tum durumu (tek nesne, degismez).
@immutable
class RobotConnectionState {
  const RobotConnectionState({
    required this.phase,
    required this.transport,
    required this.endpoint,
    this.info,
    this.latest,
    this.history = const [],
    this.stats = const LinkStats(),
    this.events = const [],
    this.lastError,
  });

  final LinkPhase phase;
  final TransportKind transport;
  final String endpoint;
  final RobotInfo? info;

  /// En son gelen telemetri (yoksa null).
  final RobotTelemetry? latest;

  /// Grafikler icin son N telemetri.
  final List<RobotTelemetry> history;
  final LinkStats stats;
  final List<LinkEvent> events;
  final String? lastError;

  bool get isLive => phase == LinkPhase.connected;

  RobotConnectionState copyWith({
    LinkPhase? phase,
    TransportKind? transport,
    String? endpoint,
    RobotInfo? info,
    RobotTelemetry? latest,
    List<RobotTelemetry>? history,
    LinkStats? stats,
    List<LinkEvent>? events,
    String? lastError,
    bool clearError = false,
  }) =>
      RobotConnectionState(
        phase: phase ?? this.phase,
        transport: transport ?? this.transport,
        endpoint: endpoint ?? this.endpoint,
        info: info ?? this.info,
        latest: latest ?? this.latest,
        history: history ?? this.history,
        stats: stats ?? this.stats,
        events: events ?? this.events,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );
}
