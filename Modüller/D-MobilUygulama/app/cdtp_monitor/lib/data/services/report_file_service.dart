import 'report_file_service_web.dart'
    if (dart.library.io) 'report_file_service_io.dart' as impl;

/// Raporların ham satırlarını saklar: yalnız ekleme (append-only) JSON Lines.
/// Silme ve güncelleme yöntemi bilerek yoktur.
abstract class ReportFileService {
  factory ReportFileService() = impl.PlatformReportFileService;

  Future<List<String>> readLines();
  Future<void> appendLine(String line);

  /// Dışa aktarma: dosya yolu (IO) ya da indirilen dosya adı (web).
  Future<String> export(String fileName, String content);
}

/// Testler ve web için bellekte çalışan sürüm.
class MemoryReportFileService implements ReportFileService {
  final lines = <String>[];

  @override
  Future<List<String>> readLines() async => List.of(lines);

  @override
  Future<void> appendLine(String line) async => lines.add(line);

  @override
  Future<String> export(String fileName, String content) async => fileName;
}
