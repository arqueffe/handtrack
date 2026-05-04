import 'package:flutter/foundation.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';

@immutable
class AppSettings {
  const AppSettings({required this.darkMode, required this.weekdayPlan});

  factory AppSettings.defaults() {
    return const AppSettings(darkMode: false, weekdayPlan: {});
  }

  final bool darkMode;
  final Map<int, SessionType> weekdayPlan;

  SessionType? plannedSessionForWeekday(int weekday) => weekdayPlan[weekday];

  AppSettings copyWith({bool? darkMode, Map<int, SessionType>? weekdayPlan}) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      weekdayPlan: weekdayPlan ?? this.weekdayPlan,
    );
  }
}
