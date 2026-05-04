import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_track/features/settings/application/settings_providers.dart';
import 'package:hand_track/features/sessions/application/session_providers.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';
import 'package:hand_track/features/sessions/presentation/session_flow_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(homeSnapshotProvider);
    final settings = ref.watch(appSettingsProvider);
    final todayPlan = settings.plannedSessionForWeekday(DateTime.now().weekday);
    final recordableTodayPlan =
        todayPlan == SessionType.strength || todayPlan == SessionType.endurance
        ? todayPlan
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Quiet training diary',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture today in under a minute. Keep the signal honest.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SessionFlowScreen(
                      initialSessionType: recordableTodayPlan,
                    ),
                  ),
                );
                ref.invalidate(homeSnapshotProvider);
                ref.invalidate(sessionsProvider);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Start today\'s session',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SignalCard(
            title: 'Today\'s plan',
            value: todayPlan == null
                ? 'No session type planned for today'
                : (todayPlan == SessionType.strength ||
                      todayPlan == SessionType.endurance)
                ? '${todayPlan.label} session planned'
                : '${todayPlan.label} planned (planning-only, not recordable)',
            icon: Icons.event_note,
          ),
          const SizedBox(height: 20),
          snapshotAsync.when(
            data: (snapshot) {
              return Column(
                children: [
                  _SignalCard(
                    title: 'Last heavy finger load',
                    value: snapshot.lastHeavyFingerLoad,
                    icon: Icons.fitness_center,
                  ),
                  const SizedBox(height: 12),
                  _SignalCard(
                    title: 'Last pull-up performance',
                    value: snapshot.lastPullingPerformance,
                    icon: Icons.north,
                  ),
                  const SizedBox(height: 12),
                  _SignalCard(
                    title: 'Session note',
                    value: snapshot.note,
                    icon: Icons.insights,
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text(
              'Could not load summary: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
