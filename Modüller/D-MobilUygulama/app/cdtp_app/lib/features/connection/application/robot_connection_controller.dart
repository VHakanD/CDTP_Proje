import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../data/ble_uart_link.dart';
import '../data/protocol_codec.dart';
import '../data/wifi_websocket_link.dart';
import '../domain/connection_state.dart';
import '../domain/robot_link.dart';
import '../domain/robot_message.dart';
import '../domain/robot_telemetry.dart';

/// Ayarlara gore dogru tasima katmanini olusturur.
/// Testlerde bu provider override edilerek sahte bir RobotLink verilebilir.
final robotLinkFactoryProvider = Provider<RobotLink Function(AppSettings)>(
  (ref) => (settings) => switch (settings.transport) {
        TransportKind.wifi => WifiWebSocketLink(settings.wsUri),
        TransportKind.ble => BleUartLink(namePrefix: settings.bleNamePrefix),
      },
);

/// Robot baglantisini yoneten ana sinif.
///
/// Gorevleri:
///  - Kullanici "Baglan" deyince kanali acar, koparsa otomatik yeniden baglanir.
///  - Gelen JSON'u cozer, son telemetriyi ve gecmisi tutar.
///  - Watchdog: 2 s'den uzun veri gelmezse durumu "Veri gelmiyor" yapar.
///  - 1 s'de bir ping gonderip gidis-donus suresini olcer.
///  - Test modulu icin telemetri akisini (telemetryStream) yayinlar.
class RobotConnectionController extends Notifier<RobotConnectionState> {
  final _codec = const ProtocolCodec();
  final _telemetryCtrl = StreamController<RobotTelemetry>.broadcast();
  final _eventCtrl = StreamController<EventMessage>.broadcast();

  RobotLink? _link;
  StreamSubscription<String>? _msgSub;
  StreamSubscription<TransportState>? _stateSub;
  Timer? _watchdog;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  /// Kullanici baglanti istiyor mu (koparsa yeniden denemek icin).
  bool _wantConnected = false;
  bool _staleReported = false;
  int _pingId = 0;
  final _pingSentAt = <int, DateTime>{};
  final _rxTimes = <DateTime>[];

  /// Test oturumu bu akisi dinler.
  Stream<RobotTelemetry> get telemetryStream => _telemetryCtrl.stream;

  /// Robotun gonderdigi olaylar (eldiven komutu vb.).
  Stream<EventMessage> get eventStream => _eventCtrl.stream;

  @override
  RobotConnectionState build() {
    final settings = ref.read(settingsProvider);
    ref.onDispose(_teardown);
    return RobotConnectionState(
      phase: LinkPhase.disconnected,
      transport: settings.transport,
      endpoint: _describe(settings),
    );
  }

  String _describe(AppSettings s) => switch (s.transport) {
        TransportKind.wifi => s.wsUri.toString(),
        TransportKind.ble => 'BLE: "${s.bleNamePrefix}*"',
      };

  /// Ayarlardaki adrese baglanir.
  Future<void> connect() async {
    _wantConnected = true;
    _reconnectTimer?.cancel();
    final settings = ref.read(settingsProvider);
    await _disposeLink();
    _link = ref.read(robotLinkFactoryProvider)(settings);
    state = state.copyWith(
      transport: settings.transport,
      endpoint: _describe(settings),
      stats: const LinkStats(),
      clearError: true,
    );
    _log('Bağlantı başlatıldı: ${_link!.endpoint}');
    await _open();
  }

  Future<void> disconnect() async {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    await _disposeLink();
    state = state.copyWith(phase: LinkPhase.disconnected);
    _log('Bağlantı kullanıcı tarafından kapatıldı');
  }

  Future<void> _open() async {
    final link = _link;
    if (link == null) return;
    state = state.copyWith(phase: LinkPhase.connecting);

    _stateSub ??= link.states.listen(_onTransportState);
    _msgSub ??= link.messages.listen(_onRaw);

    try {
      await link.connect();
    } catch (e) {
      state = state.copyWith(phase: LinkPhase.disconnected, lastError: e.toString());
      _log('Bağlanamadı: $e', LinkEventLevel.error);
      _scheduleReconnect();
      return;
    }

    final now = DateTime.now();
    _staleReported = false;
    state = state.copyWith(
      phase: LinkPhase.connected,
      endpoint: link.endpoint,
      stats: state.stats.copyWith(connectedAt: now, lastRxAt: now),
      clearError: true,
    );
    _log('Bağlandı');
    link.send(_codec.hello());

    _watchdog?.cancel();
    _watchdog = Timer.periodic(AppConstants.watchdogPeriod, (_) => _checkWatchdog());
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(AppConstants.pingInterval, (_) => _sendPing());
  }

  void _onTransportState(TransportState s) {
    final wasOpen = state.phase == LinkPhase.connected || state.phase == LinkPhase.stale;
    if (s == TransportState.disconnected && wasOpen) {
      _watchdog?.cancel();
      _pingTimer?.cancel();
      state = state.copyWith(phase: LinkPhase.disconnected);
      _log('Bağlantı koptu', LinkEventLevel.warning);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_wantConnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(AppConstants.reconnectDelay, () {
      if (!_wantConnected) return;
      state = state.copyWith(stats: state.stats.copyWith(reconnects: state.stats.reconnects + 1));
      _open();
    });
  }

  void _onRaw(String raw) {
    final now = DateTime.now();
    final msg = _codec.decode(raw, now: now);
    _registerRx(now);

    switch (msg) {
      case final TelemetryMessage m:
        _onTelemetry(m.telemetry);
      case final HelloMessage m:
        state = state.copyWith(
          info: RobotInfo(device: m.device, firmware: m.firmware, protocol: m.protocol),
        );
        _log('Robot: ${m.device}, yazılım ${m.firmware}, protokol v${m.protocol}');
        if (m.protocol != AppConstants.protocolVersion) {
          _log('Protokol sürümü uyuşmuyor (uygulama v${AppConstants.protocolVersion})',
              LinkEventLevel.warning);
        }
      case final EventMessage m:
        _eventCtrl.add(m);
        _log('Olay: ${m.name}${m.value == null ? '' : ' = ${m.value}'}');
      case final PongMessage m:
        final sent = _pingSentAt.remove(m.id);
        if (sent != null) {
          state = state.copyWith(
            stats: state.stats.copyWith(rttMs: now.difference(sent).inMilliseconds),
          );
        }
      case final UnknownMessage m:
        state = state.copyWith(
          stats: state.stats.copyWith(parseErrors: state.stats.parseErrors + 1),
        );
        _log('Çözülemeyen mesaj: ${m.reason}', LinkEventLevel.warning);
    }
  }

  /// Her gelen mesajda bosluk (gap) ve frekans hesaplanir.
  void _registerRx(DateTime now) {
    final last = state.stats.lastRxAt;
    final gap = last == null ? 0 : now.difference(last).inMilliseconds;
    final violated = gap > AppConstants.maxLinkGap.inMilliseconds;
    if (state.phase == LinkPhase.stale) {
      _log('Veri akışı yeniden başladı (boşluk ${(gap / 1000).toStringAsFixed(1)} s)');
    }
    _staleReported = false;
    state = state.copyWith(
      phase: state.phase == LinkPhase.stale ? LinkPhase.connected : state.phase,
      stats: state.stats.copyWith(
        lastRxAt: now,
        maxGapMs: gap > state.stats.maxGapMs ? gap : state.stats.maxGapMs,
        gapViolations: state.stats.gapViolations + (violated ? 1 : 0),
      ),
    );
  }

  void _onTelemetry(RobotTelemetry t) {
    _rxTimes
      ..add(t.receivedAt)
      ..removeWhere((x) => t.receivedAt.difference(x) > const Duration(seconds: 10));
    final hz = _rxTimes.length < 2
        ? null
        : (_rxTimes.length - 1) /
            (_rxTimes.last.difference(_rxTimes.first).inMilliseconds / 1000);

    final history = [...state.history, t];
    if (history.length > AppConstants.telemetryHistoryLength) history.removeAt(0);

    state = state.copyWith(
      latest: t,
      history: history,
      stats: state.stats.copyWith(
        telemetryCount: state.stats.telemetryCount + 1,
        measuredHz: hz,
      ),
    );
    _telemetryCtrl.add(t);
  }

  void _checkWatchdog() {
    final last = state.stats.lastRxAt;
    if (last == null || state.phase == LinkPhase.disconnected) return;
    final silent = DateTime.now().difference(last);
    if (silent > AppConstants.maxLinkGap && !_staleReported) {
      _staleReported = true;
      state = state.copyWith(phase: LinkPhase.stale);
      _log('2 s\'den uzun süredir veri gelmiyor', LinkEventLevel.error);
    }
  }

  void _sendPing() {
    final id = _pingId++;
    _pingSentAt[id] = DateTime.now();
    // Cevapsiz eski ping'leri biriktirme.
    _pingSentAt.removeWhere((k, _) => k < id - 10);
    _link?.send(_codec.ping(id));
  }

  /// Test basladi/bitti bilgisini robota iletir (robot yok sayabilir).
  void sendTestMarker({required String action, required String task, required String testId}) {
    _link?.send(_codec.testMarker(action: action, task: task, testId: testId));
  }

  void _log(String message, [LinkEventLevel level = LinkEventLevel.info]) {
    final events = [LinkEvent(DateTime.now(), message, level), ...state.events];
    if (events.length > AppConstants.eventLogLength) events.removeLast();
    state = state.copyWith(events: events);
  }

  Future<void> _disposeLink() async {
    _watchdog?.cancel();
    _pingTimer?.cancel();
    await _msgSub?.cancel();
    await _stateSub?.cancel();
    _msgSub = null;
    _stateSub = null;
    final link = _link;
    _link = null;
    if (link != null) await link.dispose();
  }

  void _teardown() {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    _disposeLink();
    _telemetryCtrl.close();
    _eventCtrl.close();
  }
}

final robotConnectionProvider =
    NotifierProvider<RobotConnectionController, RobotConnectionState>(
  RobotConnectionController.new,
);
