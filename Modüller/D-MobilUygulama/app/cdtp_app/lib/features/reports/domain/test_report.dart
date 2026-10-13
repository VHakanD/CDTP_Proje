import 'dart:convert';

import '../../tasks/domain/evaluation.dart';
import '../../tasks/domain/test_task.dart';

/// Kaydedilmis, degistirilemez test raporu.
///
/// [payloadJson] raporun tum icerigini (olcumler, kriterler, telemetri, video ozeti)
/// kanonik JSON olarak tutar. [hash] = SHA-256(prevHash + tum sutunlar + payloadJson),
/// bkz. ReportRepository.envelope.
/// Herhangi bir kayit veritabaninda elle degistirilirse zincir dogrulamasi bozulur.
class TestReport {
  const TestReport({
    required this.seq,
    required this.testId,
    required this.task,
    required this.verdict,
    required this.startedAt,
    required this.durationMs,
    required this.payloadJson,
    required this.prevHash,
    required this.hash,
    required this.createdAt,
  });

  /// Zincirdeki sira numarasi (1'den baslar).
  final int seq;
  final String testId;
  final TestTask task;
  final Verdict verdict;
  final DateTime startedAt;
  final int durationMs;
  final String payloadJson;
  final String prevHash;
  final String hash;
  final DateTime createdAt;

  Map<String, Object?> get payload => (jsonDecode(payloadJson) as Map).cast<String, Object?>();

  List<CriterionResult> get criteria => ((payload['criteria'] as List?) ?? const [])
      .map((e) => CriterionResult.fromJson((e as Map).cast<String, Object?>()))
      .toList();

  /// Disa aktarma (JSON dosyasi) icin tam bicim.
  Map<String, Object?> toExportJson() => {
        'seq': seq,
        'prev_hash': prevHash,
        'hash': hash,
        'created_at': createdAt.toUtc().toIso8601String(),
        'payload': payload,
      };
}

/// Veritabanina yazilacak yeni rapor (hash henuz hesaplanmamis).
class NewReport {
  const NewReport({
    required this.testId,
    required this.task,
    required this.verdict,
    required this.startedAt,
    required this.durationMs,
    required this.payload,
  });

  final String testId;
  final TestTask task;
  final Verdict verdict;
  final DateTime startedAt;
  final int durationMs;
  final Map<String, Object?> payload;
}

/// Zincir dogrulama sonucu.
class ChainVerification {
  const ChainVerification({required this.checked, this.brokenAtSeq, this.reason});

  final int checked;
  final int? brokenAtSeq;
  final String? reason;

  bool get ok => brokenAtSeq == null;
}
