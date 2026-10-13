// Platforma gore dogru video saklama kodunu secer (mobil: dosya, web: blob).
export 'video_storage_web.dart' if (dart.library.io) 'video_storage_io.dart';
