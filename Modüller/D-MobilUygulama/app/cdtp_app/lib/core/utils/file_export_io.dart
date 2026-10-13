import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Mobil surum: <uygulama belgeleri>/exports/<fileName> dosyasina yazar, yolu dondurur.
Future<String?> saveTextFile(String fileName, String content) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'exports'));
  await dir.create(recursive: true);
  final file = File(p.join(dir.path, fileName));
  await file.writeAsString(content);
  return file.path;
}
