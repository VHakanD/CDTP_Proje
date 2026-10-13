import 'package:camera/camera.dart';

import '../../../core/utils/hashing.dart';

/// Kaydedilen test videosunun bilgisi. Rapora yazilir.
class RecordedVideo {
  const RecordedVideo({required this.path, required this.sha256, required this.sizeBytes});

  final String path;

  /// Videonun SHA-256 ozeti: video sonradan degistirilirse rapordaki ozetle uyusmaz.
  final String sha256;
  final int sizeBytes;

  Map<String, Object?> toJson() => {'path': path, 'sha256': sha256, 'size_bytes': sizeBytes};
}

/// Web surumu: dosya sistemi yok, video tarayici bellegindeki blob olarak kalir.
Future<RecordedVideo> persistVideo(XFile file, String testId) async {
  final size = await file.length();
  final hash = await Hashing.sha256OfStream(file.openRead());
  return RecordedVideo(path: file.path, sha256: hash, sizeBytes: size);
}
