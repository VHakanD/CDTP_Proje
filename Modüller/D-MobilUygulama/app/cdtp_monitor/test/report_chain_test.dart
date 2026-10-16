import 'dart:convert';

import 'package:cdtp_monitor/data/repositories/report_repository.dart';
import 'package:cdtp_monitor/data/services/report_file_service.dart';
import 'package:cdtp_monitor/domain/models/criterion.dart';
import 'package:cdtp_monitor/domain/models/test_task.dart';
import 'package:cdtp_monitor/domain/use_cases/report_chain.dart';
import 'package:flutter_test/flutter_test.dart';

ReportDraft draft(CriterionResult r) => ReportDraft(
      task: TaskKind.guidance,
      startedAt: DateTime(2026, 10, 13, 14, 32, 5),
      endedAt: DateTime(2026, 10, 13, 14, 32, 19),
      criteria: [Criterion(name: 'Mesafe', measured: '0,97 m', target: '0,80–1,20 m', result: r)],
      events: const [(0, 'Test başladı'), (14200, 'Bitiş: robot durdu')],
      conditions: const {'ratio': '1:1'},
      telemetryCount: 15,
      expected: 'İLERİ',
    );

void main() {
  test('hash_is_deterministic', () {
    expect(ReportChain.hashOf({'b': 1, 'a': [2, 3]}), ReportChain.hashOf({'a': [2, 3], 'b': 1}));
    expect(ReportChain.hashOf({'a': 1}), hasLength(64));
  });

  test('chain_links_prev_hash', () async {
    final repo = ReportRepository(MemoryReportFileService());
    final r1 = await repo.seal(draft(CriterionResult.pass));
    final r2 = await repo.seal(draft(CriterionResult.fail));
    expect(r1.prevHash, ReportChain.genesis);
    expect(r2.prevHash, r1.hash);
    expect(r1.verdict, Verdict.pass);
    expect(r2.verdict, Verdict.fail);
    expect((await repo.verify(r2.id)).ok, isTrue);
  });

  test('tampered_report_detected', () async {
    final files = MemoryReportFileService();
    final repo = ReportRepository(files);
    final r1 = await repo.seal(draft(CriterionResult.fail));
    await repo.seal(draft(CriterionResult.pass));

    // Diskteki ilk raporun kararını elle "geçti" yap
    final j = jsonDecode(files.lines[0]) as Map<String, dynamic>;
    j['verdict'] = 'pass';
    files.lines[0] = jsonEncode(j);

    final check = await repo.verify(r1.id);
    expect(check.ok, isFalse);
    expect(check.brokenAtId, r1.id);
  });
}
