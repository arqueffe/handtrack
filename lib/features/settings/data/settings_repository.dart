import 'package:hand_track/features/settings/domain/app_settings.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _darkModeKey = 'settings.dark_mode';
  static const _weekdayPlanKeyPrefix = 'settings.weekday_plan.';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final plan = <int, SessionType>{};

    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      final raw = prefs.getString('$_weekdayPlanKeyPrefix$weekday');
      if (raw == null || raw.trim().isEmpty) {
        continue;
      }

      plan[weekday] = SessionTypeLabel.fromStorage(raw);
    }

    return AppSettings(
      darkMode: prefs.getBool(_darkModeKey) ?? false,
      weekdayPlan: plan,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, settings.darkMode);

    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      final key = '$_weekdayPlanKeyPrefix$weekday';
      final planned = settings.weekdayPlan[weekday];
      if (planned == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, planned.name);
      }
    }
  }
}
