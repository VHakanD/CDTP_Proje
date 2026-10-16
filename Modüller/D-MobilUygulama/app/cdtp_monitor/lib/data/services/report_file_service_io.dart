import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'report_file_service.dart';

class PlatformReportFileService implements ReportFileService {
  Future<Directory> _dir() async {
    final d = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'cdtp_reports'));
    if (!d.existsSync()) await d.create(recursive: true);
    return d;
  }

  Future<File> _file() async => File(p.join((await _dir()).path, 'reports.jsonl'));

  @override
  Future<List<String>> readLines() async {
    final f = await _file();
    if (!f.existsSync()) return [];
    return (await f.readAsLines()).where((l) => l.trim().isNotEmpty).toList();
  }

  @override
  Future<void> appendLine(String line) async {
    final f = await _file();
    await f.writeAsString('$line\n', mode: FileMode.append, flush: true);
  }

  @override
  Future<String> export(String fileName, String content) async {
    final out = File(p.join((await _dir()).path, 'export', fileName));
    await out.parent.create(recursive: true);
    await out.writeAsString(content, flush: true);
    return out.path;
  }
}
