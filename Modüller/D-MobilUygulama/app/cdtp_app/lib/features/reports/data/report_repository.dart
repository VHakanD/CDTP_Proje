import '../../../core/config/app_constants.dart';
import '../../../core/utils/hashing.dart';
import '../domain/report_store.dart';
import '../domain/test_report.dart';

/// Rapor ekleme ve hash zinciri dogrulama mantigi.
/// Depolamadan (SQLite / bellek) bagimsizdir.
class ReportRepository {
  ReportRepository(this._store);

  final ReportStore _store;

  bool get isPersistent => _store.isPersistent;

  /// Yeni raporu zincire ekler ve kaydedilen raporu dondurur.
  Future<TestReport> append(NewReport input, {DateTime? now}) async {
    final last = await _store.last();
    final prevHash = last?.hash ?? AppConstants.genesisHash;
    final unsigned = TestReport(
      seq: (last?.seq ?? 0) + 1,
      testId: input.testId,
      task: input.task,
      verdict: input.verdict,
      startedAt: input.startedAt,
      durationMs: input.durationMs,
      payloadJson: Hashing.canonicalJson(input.payload),
      prevHash: prevHash,
      hash: '',
      createdAt: now ?? DateTime.now(),
    );
    final report = TestReport(
      seq: unsigned.seq,
      testId: unsigned.testId,
      task: unsigned.task,
      verdict: unsigned.verdict,
      startedAt: unsigned.startedAt,
      durationMs: unsigned.durationMs,
      payloadJson: unsigned.payloadJson,
      prevHash: prevHash,
      hash: Hashing.chainHash(prevHash: prevHash, canonicalPayload: envelope(unsigned)),
      createdAt: unsigned.createdAt,
    );
    await _store.append(report);
    return report;
  }

  /// Hash'e giren kanonik zarf: veritabanindaki TUM sutunlar + icerik.
  /// Boylece sadece "verdict" sutunu "passed" yapilsa bile zincir bozulur.
  static String envelope(TestReport r) => Hashing.canonicalJson({
        'seq': r.seq,
        'test_id': r.testId,
        'task': r.task.name,
        'verdict': r.verdict.name,
        'started_at_ms': r.startedAt.millisecondsSinceEpoch,
        'duration_ms': r.durationMs,
        'created_at_ms': r.createdAt.millisecondsSinceEpoch,
        'payload': r.payloadJson,
      });

  Future<List<TestReport>> all() => _store.all();

  Future<TestReport?> byTestId(String id) => _store.byTestId(id);

  /// Butun zinciri bastan sona yeniden hesaplar.
  /// Bir kayit degistirildiyse ilk bozuk kaydin sira numarasini verir.
  Future<ChainVerification> verify() async {
    final items = await _store.allInChainOrder();
    var prev = AppConstants.genesisHash;
    for (final r in items) {
      if (r.prevHash != prev) {
        return ChainVerification(
          checked: r.seq,
          brokenAtSeq: r.seq,
          reason: 'Önceki kayıt bağlantısı uyuşmuyor',
        );
      }
      final expected = Hashing.chainHash(prevHash: prev, canonicalPayload: envelope(r));
      if (expected != r.hash) {
        return ChainVerification(
          checked: r.seq,
          brokenAtSeq: r.seq,
          reason: 'İçerik değiştirilmiş (hash uyuşmuyor)',
        );
      }
      prev = r.hash;
    }
    return ChainVerification(checked: items.length);
  }
}
