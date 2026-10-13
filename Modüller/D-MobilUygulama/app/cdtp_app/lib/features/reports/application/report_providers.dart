import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';
import '../domain/report_store.dart';
import '../domain/test_report.dart';

/// main.dart icinde platforma gore override edilir
/// (telefon: DriftReportStore, web: InMemoryReportStore).
final reportStoreProvider = Provider<ReportStore>((ref) => InMemoryReportStore());

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(reportStoreProvider)),
);

/// Rapor listesi. Yeni rapor eklenince `ref.invalidate(reportListProvider)` cagrilir.
final reportListProvider = FutureProvider<List<TestReport>>(
  (ref) => ref.watch(reportRepositoryProvider).all(),
);

/// Hash zinciri dogrulama sonucu (Ayarlar ve Kayitlar sayfasinda gosterilir).
final chainVerificationProvider = FutureProvider<ChainVerification>(
  (ref) => ref.watch(reportRepositoryProvider).verify(),
);
