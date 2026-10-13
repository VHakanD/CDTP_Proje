import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// Bu dosya build_runner ile uretilir:  dart run build_runner build
// Tablo tanimi degisirse komut yeniden calistirilmalidir.
part 'app_database.g.dart';

/// Test raporlari tablosu.
///
/// Ayni zamanda bir hash zinciridir: her satir bir onceki satirin
/// hash'ini (prevHash) icerir. UPDATE ve DELETE trigger ile engellenir.
@DataClassName('ReportRow')
class TestReports extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Zincir sira numarasi (1, 2, 3 ...).
  IntColumn get seq => integer().unique()();
  TextColumn get testId => text().unique()();

  /// TestTask.name (staticBalance, guidance, charging, integrated)
  TextColumn get task => text()();

  /// Verdict.name (passed, failed, incomplete)
  TextColumn get verdict => text()();
  IntColumn get startedAtMs => integer()();
  IntColumn get durationMs => integer()();

  /// Raporun tum icerigi (kanonik JSON).
  TextColumn get payloadJson => text()();
  TextColumn get prevHash => text()();
  TextColumn get chainHash => text()();
  IntColumn get createdAtMs => integer()();
}

@DriftDatabase(tables: [TestReports])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Telefonda uygulama klasorunde "cdtp_reports.sqlite" dosyasini acar.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'cdtp_reports'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Kayitlar sonradan degistirilemez / silinemez (sartname 5.2, Ö4-4).
          await customStatement('''
            CREATE TRIGGER test_reports_no_update
            BEFORE UPDATE ON test_reports
            BEGIN SELECT RAISE(ABORT, 'Test raporlari degistirilemez'); END;
          ''');
          await customStatement('''
            CREATE TRIGGER test_reports_no_delete
            BEFORE DELETE ON test_reports
            BEGIN SELECT RAISE(ABORT, 'Test raporlari silinemez'); END;
          ''');
        },
      );
}
