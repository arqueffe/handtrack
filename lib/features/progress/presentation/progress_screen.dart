import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hand_track/features/sessions/application/session_providers.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int? _selectedEdgeMm;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _ProgressHeader(),
              SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'No sessions yet. Log a few sessions and this tab will show finger, pulling, climbing, and per-edge trends.',
                  ),
                ),
              ),
            ],
          );
        }

        final chronological = sessions.reversed.toList(growable: false);
        final fingerSessions = chronological
            .where((session) => session.finger != null)
            .toList(growable: false);
        final edgeOptions =
            fingerSessions
                .map((session) => session.finger!.edgeMm)
                .toSet()
                .toList()
              ..sort();

        final selectedEdge = edgeOptions.contains(_selectedEdgeMm)
            ? _selectedEdgeMm
            : edgeOptions.isNotEmpty
            ? edgeOptions.first
            : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _ProgressHeader(),
            const SizedBox(height: 14),
            _SummaryStrip(sessions: sessions, edgeCount: edgeOptions.length),
            const SizedBox(height: 14),
            _TrendCard(
              title: 'Finger strength trend',
              subtitle:
                  'Normalized finger-load score (load adjusted by RPE) across all logged finger sessions.',
              points: _fingerPoints(chronological),
              color: const Color(0xFF0EA5A4),
            ),
            const SizedBox(height: 14),
            _TrendCard(
              title: 'Pulling strength trend',
              subtitle: 'Volume-intensity score from weighted pulling entries.',
              points: _pullingPoints(chronological),
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(height: 14),
            _TrendCard(
              title: 'Climbing output trend',
              subtitle:
                  'Grade plus send-efficiency trend across climbing sessions.',
              points: _climbingPoints(chronological),
              color: const Color(0xFFEA580C),
            ),
            const SizedBox(height: 14),
            _EdgeProgressCard(
              selectedEdge: selectedEdge,
              edgeOptions: edgeOptions,
              sessions: chronological,
              onEdgeSelected: (edge) {
                setState(() {
                  _selectedEdgeMm = edge;
                });
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }

  List<FlSpot> _fingerPoints(List<TrainingSession> sessions) {
    final points = <FlSpot>[];
    var x = 0;
    for (final session in sessions) {
      final finger = session.finger;
      if (finger != null) {
        points.add(FlSpot(x.toDouble(), _normalizedFingerScore(finger)));
      }
      x++;
    }
    return points;
  }

  List<FlSpot> _pullingPoints(List<TrainingSession> sessions) {
    final points = <FlSpot>[];
    var x = 0;
    for (final session in sessions) {
      final pulling = session.pulling;
      if (pulling != null) {
        final score = (pulling.loadKg * pulling.reps) / 10;
        points.add(FlSpot(x.toDouble(), score));
      }
      x++;
    }
    return points;
  }

  List<FlSpot> _climbingPoints(List<TrainingSession> sessions) {
    final points = <FlSpot>[];
    var x = 0;
    for (final session in sessions) {
      final climbing = session.climbing;
      if (climbing != null) {
        final gradeScore = SessionScoring.gradeToScore(climbing.topGrade) ?? 0;
        final tries = climbing.attempts == 0 ? 1 : climbing.attempts;
        final score = gradeScore + ((climbing.sends / tries) * 4);
        points.add(FlSpot(x.toDouble(), score));
      }
      x++;
    }
    return points;
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 26),
        ),
        SizedBox(height: 4),
        Text(
          'Look for direction, not noise. Compare the same stress points over time.',
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.sessions, required this.edgeCount});

  final List<TrainingSession> sessions;
  final int edgeCount;

  @override
  Widget build(BuildContext context) {
    final latest = sessions.first;
    final latestDate = DateFormat('MMM d').format(latest.sessionDate);
    final strengthCount = sessions
        .where((session) => session.sessionType == SessionType.strength)
        .length;
    final enduranceCount = sessions
        .where((session) => session.sessionType == SessionType.endurance)
        .length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _KpiCard(label: 'Sessions', value: '${sessions.length}'),
        _KpiCard(label: 'Latest', value: latestDate),
        _KpiCard(label: 'Edges tracked', value: '$edgeCount'),
        _KpiCard(
          label: 'Strength / Endurance',
          value: '$strengthCount / $enduranceCount',
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.color,
  });

  final String title;
  final String subtitle;
  final List<FlSpot> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final delta = points.length > 1 ? points.last.y - points.first.y : null;
    final deltaLabel = delta == null
        ? 'Need more data'
        : delta >= 0
        ? 'Up ${delta.toStringAsFixed(2)}'
        : 'Down ${delta.abs().toStringAsFixed(2)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  deltaLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: delta == null
                        ? Colors.grey.shade700
                        : delta >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 10),
            SizedBox(
              height: 170,
              child: points.isEmpty
                  ? const Center(
                      child: Text('No entries logged for this metric yet.'),
                    )
                  : _SimpleLineChart(points: points, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeProgressCard extends StatelessWidget {
  const _EdgeProgressCard({
    required this.selectedEdge,
    required this.edgeOptions,
    required this.sessions,
    required this.onEdgeSelected,
  });

  final int? selectedEdge;
  final List<int> edgeOptions;
  final List<TrainingSession> sessions;
  final ValueChanged<int> onEdgeSelected;

  @override
  Widget build(BuildContext context) {
    if (edgeOptions.isEmpty || selectedEdge == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Edge progress will appear once finger sessions are logged with edge size and load.',
          ),
        ),
      );
    }

    final edgeSessions = sessions
        .where((session) => session.finger?.edgeMm == selectedEdge)
        .toList(growable: false);
    final points = <FlSpot>[];
    for (var i = 0; i < edgeSessions.length; i++) {
      points.add(
        FlSpot(i.toDouble(), _normalizedFingerScore(edgeSessions[i].finger!)),
      );
    }

    final latest = edgeSessions.last.finger!;
    final bestLoad = edgeSessions
        .map((session) => session.finger!.addedKg)
        .reduce((a, b) => a > b ? a : b);
    final avgRpe =
        edgeSessions
            .map((session) => session.finger!.rpe)
            .reduce((a, b) => a + b) /
        edgeSessions.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edge progress',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick an edge size to compare performance on that exact grip over time.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final edge in edgeOptions)
                  ChoiceChip(
                    label: Text('$edge mm'),
                    selected: edge == selectedEdge,
                    onSelected: (_) => onEdgeSelected(edge),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _KpiCard(label: 'Entries', value: '${edgeSessions.length}'),
                _KpiCard(
                  label: 'Latest load',
                  value: '${latest.addedKg.toStringAsFixed(1)} kg',
                ),
                _KpiCard(
                  label: 'Best load',
                  value: '${bestLoad.toStringAsFixed(1)} kg',
                ),
                _KpiCard(label: 'Avg RPE', value: avgRpe.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: points.length < 2
                  ? const Center(
                      child: Text(
                        'Need at least 2 entries on this edge to show a trend.',
                      ),
                    )
                  : _SimpleLineChart(
                      points: points,
                      color: const Color(0xFF14B8A6),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({required this.points, required this.color});

  final List<FlSpot> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black12),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            color: color,
            barWidth: 2.8,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

double _normalizedFingerScore(FingerLog finger) {
  return finger.addedKg - ((finger.rpe - 6) * 0.35);
}
