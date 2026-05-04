import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_track/features/settings/application/settings_providers.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.darkMode,
                  onChanged: (value) {
                    controller.setDarkMode(value);
                  },
                  title: Text('Dark mode'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly session plan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a default session type for each day. The Today screen will show this and preselect it when starting a session.',
                ),
                const SizedBox(height: 12),
                for (final weekday in _weekdayOrder)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(_weekdayLabel(weekday)),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<SessionType?>(
                            initialValue: settings.weekdayPlan[weekday],
                            items: [
                              const DropdownMenuItem<SessionType?>(
                                value: null,
                                child: Text('No plan'),
                              ),
                              ...SessionType.values.map(
                                (type) => DropdownMenuItem<SessionType?>(
                                  value: type,
                                  child: Text(type.label),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              controller.setWeekdayPlan(weekday, value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text('All preferences are stored locally on-device.'),
          ),
        ),
      ],
    );
  }
}

const _weekdayOrder = <int>[
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
];

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Monday';
    case DateTime.tuesday:
      return 'Tuesday';
    case DateTime.wednesday:
      return 'Wednesday';
    case DateTime.thursday:
      return 'Thursday';
    case DateTime.friday:
      return 'Friday';
    case DateTime.saturday:
      return 'Saturday';
    default:
      return 'Sunday';
  }
}
