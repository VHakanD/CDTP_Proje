import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

/// Ayarlari telefonda kalici olarak saklar (SharedPreferences, tek JSON anahtar).
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const _key = 'app_settings_v1';
  final SharedPreferences _prefs;

  AppSettings load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } catch (_) {
      // Bozuk kayit varsa varsayilanlara don.
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) =>
      _prefs.setString(_key, jsonEncode(settings.toJson()));
}
