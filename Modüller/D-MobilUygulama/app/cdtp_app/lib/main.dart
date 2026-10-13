import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/db/app_database.dart';
import 'features/reports/application/report_providers.dart';
import 'features/reports/data/drift_report_store.dart';
import 'features/reports/domain/report_store.dart';
import 'features/settings/application/settings_controller.dart';

/// Uygulama girisi.
///
/// Platforma bagli servisler burada secilip Riverpod'a verilir:
///  - Ayarlar: SharedPreferences
///  - Raporlar: telefonda SQLite (drift), web onizlemede bellek
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final ReportStore reportStore =
      kIsWeb ? InMemoryReportStore() : DriftReportStore(AppDatabase.open());

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        reportStoreProvider.overrideWithValue(reportStore),
      ],
      child: const CdtpApp(),
    ),
  );
}
