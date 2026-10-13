import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

/// main.dart icinde gercek SharedPreferences ile override edilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider main.dart icinde override edilmeli'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Uygulamanin anlik ayarlari. Degisiklikler aninda kaydedilir.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(AppSettings Function(AppSettings current) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).save(state);
  }

  Future<void> updateThresholds(EvaluationThresholds Function(EvaluationThresholds t) change) =>
      update((s) => s.copyWith(thresholds: change(s.thresholds)));

  Future<void> resetThresholds() =>
      update((s) => s.copyWith(thresholds: const EvaluationThresholds()));
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
