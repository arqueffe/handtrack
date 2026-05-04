import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_track/features/settings/data/settings_repository.dart';
import 'package:hand_track/features/settings/domain/app_settings.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends Notifier<AppSettings> {
  late final SettingsRepository _repository;

  @override
  AppSettings build() {
    _repository = ref.watch(settingsRepositoryProvider);
    unawaited(_load());
    return AppSettings.defaults();
  }

  Future<void> _load() async {
    state = await _repository.load();
  }

  Future<void> setDarkMode(bool enabled) async {
    state = state.copyWith(darkMode: enabled);
    await _repository.save(state);
  }

  Future<void> setWeekdayPlan(int weekday, SessionType? sessionType) async {
    final updated = Map<int, SessionType>.from(state.weekdayPlan);
    if (sessionType == null) {
      updated.remove(weekday);
    } else {
      updated[weekday] = sessionType;
    }

    state = state.copyWith(weekdayPlan: updated);
    await _repository.save(state);
  }
}
