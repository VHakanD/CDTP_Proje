import 'package:drift/drift.dart';

import '../../../data/db/app_database.dart';
import '../../tasks/domain/evaluation.dart';
import '../../tasks/domain/test_task.dart';
import '../domain/report_store.dart';
import '../domain/test_report.dart';

/// Raporlari telefondaki SQLite veritabaninda saklar (drift).
class DriftReportStore implements ReportStore {
  DriftReportStore(this._db);

  final AppDatabase _db;

  @override
  bool get isPersistent => true;

  @override
  Future<TestReport?> last() async {
    final query = _db.select(_db.testReports)
      ..orderBy([(t) => OrderingTerm.desc(t.seq)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> append(TestReport r) async {
    await _db.into(_db.testReports).insert(
          TestReportsCompanion.insert(
            seq: r.seq,
            testId: r.testId,
            task: r.task.name,
            verdict: r.verdict.name,
            startedAtMs: r.startedAt.millisecondsSinceEpoch,
            durationMs: r.durationMs,
            payloadJson: r.payloadJson,
            prevHash: r.prevHash,
            chainHash: r.hash,
            createdAtMs: r.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<List<TestReport>> all() async {
    final rows = await (_db.select(_db.testReports)
          ..orderBy([(t) => OrderingTerm.desc(t.seq)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<TestReport>> allInChainOrder() async {
    final rows = await (_db.select(_db.testReports)
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<TestReport?> byTestId(String testId) async {
    final row = await (_db.select(_db.testReports)..where((t) => t.testId.equals(testId)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  TestReport _toDomain(ReportRow row) => TestReport(
        seq: row.seq,
        testId: row.testId,
        task: TestTask.values.byName(row.task),
        verdict: Verdict.values.byName(row.verdict),
        startedAt: DateTime.fromMillisecondsSinceEpoch(row.startedAtMs),
        durationMs: row.durationMs,
        payloadJson: row.payloadJson,
        prevHash: row.prevHash,
        hash: row.chainHash,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      );
}
