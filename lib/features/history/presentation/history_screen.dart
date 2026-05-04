import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hand_track/features/sessions/application/session_providers.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(
            child: Text('No sessions yet. Start one from Today.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _HistoryCard(session: session);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, MMM d').format(session.sessionDate);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.sessionType.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(dateLabel),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Fatigue ${session.bodyState.fatigue}/10, finger sensitivity ${session.bodyState.fingerSensitivity}/10',
            ),
            if (session.finger != null)
              Text(
                'Finger: ${session.finger!.edgeMm} mm, ${session.finger!.addedKg.toStringAsFixed(1)} kg @ RPE ${session.finger!.rpe}',
              ),
            if (session.pulling != null)
              Text(
                'Pulling: ${session.pulling!.loadKg.toStringAsFixed(1)} kg x ${session.pulling!.reps}',
              ),
            if (session.strengthDetails != null)
              Text(
                'Strength: max hangs ${session.strengthDetails!.maxHangSets}x${session.strengthDetails!.maxHangReps} @ ${session.strengthDetails!.hangSeconds}s, pull-ups ${session.strengthDetails!.weightedPullupSets}x${session.strengthDetails!.weightedPullupReps} (rest ${session.strengthDetails!.weightedPullupRestSeconds}s)',
              ),
            if (session.enduranceDetails != null)
              Text(
                session.enduranceDetails!.protocol ==
                        EnduranceProtocol.repeaters
                    ? 'Endurance: repeaters ${session.enduranceDetails!.rounds} rounds, ${session.enduranceDetails!.workSeconds}s/${session.enduranceDetails!.restSeconds}s, set rest ${session.enduranceDetails!.setRestSeconds}s x ${session.enduranceDetails!.sets} sets'
                    : 'Endurance: intermittent ${session.enduranceDetails!.rounds} rounds, ${session.enduranceDetails!.workSeconds}s/${session.enduranceDetails!.restSeconds}s x ${session.enduranceDetails!.sets} sets',
              ),
            if (session.climbing != null)
              Text(
                'Climbing: ${session.climbing!.topGrade}, ${session.climbing!.sends}/${session.climbing!.attempts} sends/attempts',
              ),
            if (session.notes.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  session.notes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
