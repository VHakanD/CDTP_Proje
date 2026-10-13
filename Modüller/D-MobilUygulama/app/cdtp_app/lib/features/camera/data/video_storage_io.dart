import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/hashing.dart';
import 'video_storage_web.dart' show RecordedVideo;

export 'video_storage_web.dart' show RecordedVideo;

/// Android/iOS surumu: gecici video dosyasini uygulama klasorune tasir
/// (<belgeler>/videos/<testId>.mp4) ve SHA-256 ozetini hesaplar.
Future<RecordedVideo> persistVideo(XFile file, String testId) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'videos'));
  await dir.create(recursive: true);
  final ext = p.extension(file.path).isEmpty ? '.mp4' : p.extension(file.path);
  final target = p.join(dir.path, '$testId$ext');
  await file.saveTo(target);

  final f = File(target);
  final hash = await Hashing.sha256OfStream(f.openRead());
  return RecordedVideo(path: target, sha256: hash, sizeBytes: await f.length());
}
