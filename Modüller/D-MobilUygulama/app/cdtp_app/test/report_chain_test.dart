import 'package:cdtp_robot_app/core/config/app_constants.dart';
import 'package:cdtp_robot_app/features/reports/data/report_repository.dart';
import 'package:cdtp_robot_app/features/reports/domain/report_store.dart';
import 'package:cdtp_robot_app/features/reports/domain/test_report.dart';
import 'package:cdtp_robot_app/features/tasks/domain/evaluation.dart';
import 'package:cdtp_robot_app/features/tasks/domain/test_task.dart';
import 'package:flutter_test/flutter_test.dart';

NewReport _report(String id, Verdict v) => NewReport(
      testId: id,
      task: TestTask.staticBalance,
      verdict: v,
      startedAt: DateTime(2026, 10, 13),
      durationMs: 31000,
      payload: {'test_id': id, 'verdict': v.name, 'metrics': {'balanced_s': 31.0}},
    );

void main() {
  test('raporlar zincir halinde eklenir ve dogrulanir', () async {
    final repo = ReportRepository(InMemoryReportStore());
    final a = await repo.append(_report('A', Verdict.passed));
    final b = await repo.append(_report('B', Verdict.failed));

    expect(a.seq, 1);
    expect(a.prevHash, AppConstants.genesisHash);
    expect(b.seq, 2);
    expect(b.prevHash, a.hash);

    final v = await repo.verify();
    expect(v.ok, isTrue);
    expect(v.checked, 2);
  });

  test('kaydedilmis bir rapor elle "GECTI" yapilirsa zincir bozulur', () async {
    final store = InMemoryReportStore();
    final repo = ReportRepository(store);
    await repo.append(_report('A', Verdict.passed));
    final b = await repo.append(_report('B', Verdict.failed));
    await repo.append(_report('C', Verdict.passed));

    // B kaydinin icerigi degistirilir, hash ayni birakilir.
    store.debugTamper(
      1,
      TestReport(
        seq: b.seq,
        testId: b.testId,
        task: b.task,
        verdict: Verdict.passed,
        startedAt: b.startedAt,
        durationMs: b.durationMs,
        payloadJson: b.payloadJson.replaceAll('failed', 'passed'),
        prevHash: b.prevHash,
        hash: b.hash,
        createdAt: b.createdAt,
      ),
    );

    final v = await repo.verify();
    expect(v.ok, isFalse);
    expect(v.brokenAtSeq, 2);
  });

  test('sadece sonuc sutunu degistirilirse de zincir bozulur', () async {
    final store = InMemoryReportStore();
    final repo = ReportRepository(store);
    final a = await repo.append(_report('A', Verdict.failed));

    store.debugTamper(
      0,
      TestReport(
        seq: a.seq,
        testId: a.testId,
        task: a.task,
        verdict: Verdict.passed,
        startedAt: a.startedAt,
        durationMs: a.durationMs,
        payloadJson: a.payloadJson,
        prevHash: a.prevHash,
        hash: a.hash,
        createdAt: a.createdAt,
      ),
    );

    final v = await repo.verify();
    expect(v.ok, isFalse);
    expect(v.brokenAtSeq, 1);
  });

  test('ayni icerik her zaman ayni hash i uretir (anahtar sirasi onemsiz)', () async {
    final r1 = await ReportRepository(InMemoryReportStore()).append(
      NewReport(
        testId: 'X',
        task: TestTask.charging,
        verdict: Verdict.passed,
        startedAt: DateTime(2026),
        durationMs: 1,
        payload: {'b': 1, 'a': 2},
      ),
      now: DateTime(2026),
    );
    final r2 = await ReportRepository(InMemoryReportStore()).append(
      NewReport(
        testId: 'X',
        task: TestTask.charging,
        verdict: Verdict.passed,
        startedAt: DateTime(2026),
        durationMs: 1,
        payload: {'a': 2, 'b': 1},
      ),
      now: DateTime(2026),
    );
    expect(r1.hash, r2.hash);
  });
}
