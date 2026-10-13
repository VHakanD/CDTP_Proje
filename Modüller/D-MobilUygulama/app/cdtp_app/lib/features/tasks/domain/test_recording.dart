import '../../camera/domain/motion_sample.dart';
import '../../connection/domain/connection_state.dart';
import '../../connection/domain/robot_telemetry.dart';
import 'test_task.dart';

/// Testin neden bittigi.
enum EndReason {
  manual('Kullanıcı bitirdi'),
  completed('Bitiş koşulu sağlandı'),
  timeout('Süre doldu'),
  fallDetected('Düşme tespit edildi');

  const EndReason(this.label);
  final String label;
}

/// Robottan gelen anlik olay (orn. eldiven komutu) kaydi.
class RecordedEvent {
  const RecordedEvent({required this.time, required this.name, this.value});
  final DateTime time;
  final String name;
  final Object? value;

  Map<String, Object?> toJson() => {
        't': time.toUtc().toIso8601String(),
        'name': name,
        if (value != null) 'value': value,
      };
}

/// Bir test boyunca toplanan ham veri. Degerlendirme sadece buna bakar;
/// boylece degerlendiriciler arayuzden bagimsiz test edilebilir.
class TestRecording {
  TestRecording({
    required this.testId,
    required this.task,
    required this.params,
    required this.startedAt,
    this.endedAt,
    List<RobotTelemetry>? telemetry,
    List<MotionSample>? motion,
    List<RecordedEvent>? events,
    this.trackerImplemented = false,
    this.robotInfo,
  })  : telemetry = telemetry ?? [],
        motion = motion ?? [],
        events = events ?? [];

  final String testId;
  final TestTask task;
  final TaskParams params;

  /// "Testi Baslat" ani (sartname: test suresinin baslangic zaman damgasi).
  final DateTime startedAt;
  DateTime? endedAt;
  final List<RobotTelemetry> telemetry;
  final List<MotionSample> motion;
  final List<RecordedEvent> events;
  final bool trackerImplemented;
  final RobotInfo? robotInfo;

  Duration elapsedAt(DateTime now) => (endedAt ?? now).difference(startedAt);

  Duration get duration => elapsedAt(DateTime.now());
}
