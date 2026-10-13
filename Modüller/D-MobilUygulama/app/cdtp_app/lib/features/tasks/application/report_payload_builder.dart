import '../../../core/config/app_constants.dart';
import '../../camera/data/video_storage.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/evaluation.dart';
import '../domain/evaluators/common_criteria.dart';
import '../domain/test_recording.dart';

/// Test bitince veritabanina yazilacak rapor icerigini (payload) olusturur.
///
/// Rapor kendi kendini aciklar: kullanilan esikler, ham telemetri, kamera
/// ornekleri, video ozeti ve kriter sonuclari hep birlikte saklanir.
class ReportPayloadBuilder {
  const ReportPayloadBuilder();

  static const schemaVersion = 1;

  Map<String, Object?> build({
    required TestRecording rec,
    required EvaluationResult evaluation,
    required EvaluationThresholds thresholds,
    required EndReason endReason,
    required String trackerName,
    RecordedVideo? video,
    String platform = 'unknown',
  }) {
    final end = rec.endedAt ?? DateTime.now();
    final info = rec.robotInfo;
    return {
      'schema': schemaVersion,
      'test_id': rec.testId,
      'task': rec.task.name,
      'task_title': rec.task.title,
      'module': rec.task.module,
      'rubric': rec.task.rubric,
      'params': rec.params.toJson(),
      'started_at': rec.startedAt.toUtc().toIso8601String(),
      'ended_at': end.toUtc().toIso8601String(),
      'duration_ms': end.difference(rec.startedAt).inMilliseconds,
      'end_reason': endReason.name,
      'verdict': evaluation.verdict.name,
      'criteria': evaluation.criteria.map((c) => c.toJson()).toList(),
      'metrics': _jsonSafe(evaluation.metrics),
      'thresholds': thresholds.toJson(),
      'link': {
        'telemetry_count': rec.telemetry.length,
        'max_gap_s': CommonCriteria.maxGapSeconds(rec),
        'rate_hz': CommonCriteria.measuredHz(rec),
      },
      'robot': info == null
          ? null
          : {'device': info.device, 'firmware': info.firmware, 'protocol': info.protocol},
      'tracker': {'name': trackerName, 'implemented': rec.trackerImplemented},
      'video': video?.toJson(),
      'app': {
        'version': AppConstants.appVersion,
        'protocol': AppConstants.protocolVersion,
        'platform': platform,
      },
      'telemetry': rec.telemetry.map((t) => t.toJson()).toList(),
      'motion': rec.motion.map((m) => m.toJson()).toList(),
      'events': rec.events.map((e) => e.toJson()).toList(),
    };
  }

  /// JSON'a yazilamayan sayilari (NaN, sonsuz) null yapar.
  static Map<String, Object?> _jsonSafe(Map<String, Object?> m) => {
        for (final e in m.entries)
          e.key: (e.value is double && !(e.value as double).isFinite) ? null : e.value,
      };
}
