import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/test_report.dart';

class ChainCheck {
  const ChainCheck.ok() : ok = true, brokenAtId = null;
  const ChainCheck.broken(this.brokenAtId) : ok = false;

  final bool ok;
  final String? brokenAtId;
}

/// SHA-256 hash zinciri: her rapor bir öncekinin hash'ini içerir. Bir rapor
/// sonradan değiştirilirse kendi hash'i ve sonraki bağlantı bozulur.
abstract final class ReportChain {
  static const genesis = '0000000000000000000000000000000000000000000000000000000000000000';

  static String hashOf(Map<String, dynamic> body) =>
      sha256.convert(utf8.encode(canonicalJson(body))).toString();

  /// Anahtarları sıralı JSON: aynı içerik her zaman aynı metni üretir.
  static String canonicalJson(Object? v) => jsonEncode(_sorted(v));

  static Object? _sorted(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _sorted(v[k])};
    }
    if (v is List) return [for (final e in v) _sorted(e)];
    return v;
  }

  /// [reports] eskiden yeniye sıralı olmalıdır.
  static ChainCheck verify(List<TestReport> reports) {
    var prev = genesis;
    for (final r in reports) {
      if (r.prevHash != prev || hashOf(r.body()) != r.hash) return ChainCheck.broken(r.id);
      prev = r.hash;
    }
    return const ChainCheck.ok();
  }
}
