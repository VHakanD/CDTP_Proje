import 'test_report.dart';

/// Raporlarin fiziksel olarak saklandigi yer.
///
/// Sadece EKLEME ve OKUMA vardir; guncelleme/silme yontemi bilerek yoktur
/// (sartname: kayit sonradan degistirilemez).
///  - Telefonda: DriftReportStore (SQLite, UPDATE/DELETE trigger ile engelli)
///  - Web ve testlerde: InMemoryReportStore
abstract class ReportStore {
  /// Zincirdeki son rapor (yoksa null).
  Future<TestReport?> last();

  /// Raporu ekler. [report.seq] son seq + 1 olmalidir.
  Future<void> append(TestReport report);

  /// Tum raporlar, yeniden eskiye.
  Future<List<TestReport>> all();

  /// Tum raporlar, zincir sirasinda (eskiden yeniye). Dogrulama icin.
  Future<List<TestReport>> allInChainOrder();

  Future<TestReport?> byTestId(String testId);

  /// Kalici mi (web'de false).
  bool get isPersistent;
}

/// Bellekte tutan basit implementasyon (web onizleme ve birim testleri).
class InMemoryReportStore implements ReportStore {
  final _items = <TestReport>[];

  @override
  bool get isPersistent => false;

  @override
  Future<TestReport?> last() async => _items.isEmpty ? null : _items.last;

  @override
  Future<void> append(TestReport report) async => _items.add(report);

  @override
  Future<List<TestReport>> all() async => _items.reversed.toList();

  @override
  Future<List<TestReport>> allInChainOrder() async => List.unmodifiable(_items);

  @override
  Future<TestReport?> byTestId(String testId) async {
    for (final r in _items) {
      if (r.testId == testId) return r;
    }
    return null;
  }

  /// Sadece testlerde: bir kaydin elle degistirilmesini taklit eder.
  void debugTamper(int index, TestReport replacement) => _items[index] = replacement;
}
