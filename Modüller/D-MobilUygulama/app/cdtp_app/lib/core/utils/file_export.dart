// Platforma gore dosya yazma (mobil: dosya, web: desteklenmez).
export 'file_export_web.dart' if (dart.library.io) 'file_export_io.dart';
