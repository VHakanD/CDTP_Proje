import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Rapor butunlugu icin yardimci fonksiyonlar.
///
/// Ayni veri her zaman ayni hash'i uretsin diye JSON anahtarlari alfabetik
/// siralanarak (kanonik JSON) yazilir.
class Hashing {
  Hashing._();

  /// Map/List yapisini anahtarlari sirali sekilde JSON metnine cevirir.
  static String canonicalJson(Object? value) => jsonEncode(_sortKeys(value));

  static Object? _sortKeys(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _sortKeys(value[k])};
    }
    if (value is List) return value.map(_sortKeys).toList();
    return value;
  }

  static String sha256Hex(String text) => sha256.convert(utf8.encode(text)).toString();

  /// Zincir hash'i: onceki kaydin hash'i + bu kaydin kanonik icerigi.
  /// Bir kayit degistirilirse kendisinden sonraki tum hash'ler tutarsiz hale gelir.
  static String chainHash({required String prevHash, required String canonicalPayload}) =>
      sha256Hex('$prevHash\n$canonicalPayload');

  /// Buyuk dosyalari (video) parca parca okuyarak SHA-256 hesaplar.
  static Future<String> sha256OfStream(Stream<List<int>> bytes) async {
    final digest = await sha256.bind(bytes).first;
    return digest.toString();
  }
}
