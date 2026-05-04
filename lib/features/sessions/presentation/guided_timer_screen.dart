import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';

enum GuidedPhaseType { warmup, work, rest, core }

class GuidedSessionResult {
  const GuidedSessionResult({
    required this.completed,
    required this.aborted,
    required this.plannedTotalSeconds,
    required this.elapsedSeconds,
    required this.completedExercises,
    required this.totalExercises,
    required this.completedPhases,
    required this.totalPhases,
    required this.skippedPhases,
    required this.finishedAt,
  });

  final bool completed;
  final bool aborted;
  final int plannedTotalSeconds;
  final int elapsedSeconds;
  final int completedExercises;
  final int totalExercises;
  final int completedPhases;
  final int totalPhases;
  final int skippedPhases;
  final DateTime finishedAt;
}

class GuidedTimerPhase {
  const GuidedTimerPhase({
    required this.label,
    required this.durationSeconds,
    required this.type,
  });

  final String label;
  final int durationSeconds;
  final GuidedPhaseType type;
}

class GuidedTimerExercise {
  const GuidedTimerExercise({required this.name, required this.phases});

  final String name;
  final List<GuidedTimerPhase> phases;
}

class GuidedSessionTimerScreen extends StatefulWidget {
  const GuidedSessionTimerScreen({
    super.key,
    required this.sessionType,
    required this.warmupSeconds,
    required this.plannedTotalSeconds,
    required this.exercises,
  });

  final SessionType sessionType;
  final int warmupSeconds;
  final int plannedTotalSeconds;
  final List<GuidedTimerExercise> exercises;

  @override
  State<GuidedSessionTimerScreen> createState() =>
      _GuidedSessionTimerScreenState();
}

class _GuidedSessionTimerScreenState extends State<GuidedSessionTimerScreen> {
  Timer? _ticker;

  int _maxInt(int a, int b) => a > b ? a : b;

  bool _running = false;
  bool _completed = false;
  bool _awaitingNextExercise = false;
  bool _inWarmup = false;
  bool _isTransitioning = false;
  bool _didPop = false;

  int _remainingSeconds = 0;
  int _currentExerciseIndex = 0;
  int _currentPhaseIndex = 0;
  int _elapsedSeconds = 0;
  int _completedPhases = 0;
  int _skippedPhases = 0;

  late final int _totalPhaseCount;

  @override
  void initState() {
    super.initState();
    _totalPhaseCount = _calculateTotalPhases();
    _configureInitialPhase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _completed || _awaitingNextExercise) {
        return;
      }
      unawaited(_kickoff());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _configureInitialPhase() {
    if (widget.exercises.isEmpty) {
      _completed = true;
      return;
    }

    if (widget.warmupSeconds > 0) {
      _inWarmup = true;
      _remainingSeconds = widget.warmupSeconds;
    } else {
      _inWarmup = false;
      _remainingSeconds = _currentPhase.durationSeconds;
    }
  }

  GuidedTimerExercise get _currentExercise =>
      widget.exercises[_currentExerciseIndex];

  GuidedTimerPhase get _currentPhase =>
      _currentExercise.phases[_currentPhaseIndex];

  GuidedPhaseType get _activePhaseType {
    if (_inWarmup) {
      return GuidedPhaseType.warmup;
    }
    return _currentPhase.type;
  }

  String get _currentLabel {
    if (_inWarmup) {
      return 'Warm-up';
    }
    return _currentPhase.label;
  }

  int get _totalExerciseCount => widget.exercises.length;

  int get _activePhaseTotalSeconds {
    if (_inWarmup) {
      return widget.warmupSeconds;
    }
    return _currentPhase.durationSeconds;
  }

  Future<void> _kickoff() async {
    await _playPhaseCue(_activePhaseType);
    if (!mounted || _completed || _awaitingNextExercise) {
      return;
    }
    _startTicker();
  }

  int _calculateTotalPhases() {
    var total = widget.warmupSeconds > 0 ? 1 : 0;
    for (final exercise in widget.exercises) {
      total += exercise.phases.length;
    }
    return total;
  }

  int _exerciseDurationSeconds(GuidedTimerExercise exercise) {
    var total = 0;
    for (final phase in exercise.phases) {
      total += phase.durationSeconds;
    }
    return total;
  }

  void _togglePause() {
    if (_completed || _awaitingNextExercise) {
      return;
    }

    if (_running) {
      _pause();
    } else {
      _startTicker();
    }
  }

  void _pause() {
    _ticker?.cancel();
    setState(() {
      _running = false;
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 0) {
        unawaited(_finishCurrentPhase(skipped: false));
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
        _elapsedSeconds += 1;
      });

      if (_remainingSeconds <= 0) {
        unawaited(_finishCurrentPhase(skipped: false));
      }
    });

    setState(() {
      _running = true;
    });
  }

  Future<void> _finishCurrentPhase({required bool skipped}) async {
    if (_isTransitioning || _completed) {
      return;
    }
    _isTransitioning = true;
    _ticker?.cancel();
    setState(() {
      _running = false;
      if (skipped) {
        _skippedPhases += 1;
      } else {
        _completedPhases += 1;
      }
    });

    if (_inWarmup) {
      _inWarmup = false;
      _remainingSeconds = _currentPhase.durationSeconds;
      await _playPhaseCue(_currentPhase.type);
      _isTransitioning = false;
      _startTicker();
      return;
    }

    final hasNextPhase =
        _currentPhaseIndex < _currentExercise.phases.length - 1;
    if (hasNextPhase) {
      _currentPhaseIndex += 1;
      _remainingSeconds = _currentPhase.durationSeconds;
      await _playPhaseCue(_currentPhase.type);
      _isTransitioning = false;
      _startTicker();
      return;
    }

    final hasNextExercise = _currentExerciseIndex < _totalExerciseCount - 1;
    if (hasNextExercise) {
      setState(() {
        _running = false;
        _awaitingNextExercise = true;
      });
      await _playTransitionCue();
      _isTransitioning = false;
      return;
    }

    setState(() {
      _running = false;
      _completed = true;
    });
    await _playCompletionCue();
    _isTransitioning = false;
  }

  Future<void> _startNextExercise() async {
    if (!_awaitingNextExercise || _completed) {
      return;
    }

    setState(() {
      _awaitingNextExercise = false;
      _currentExerciseIndex += 1;
      _currentPhaseIndex = 0;
      _remainingSeconds = _currentPhase.durationSeconds;
      _running = false;
    });

    await _playPhaseCue(_currentPhase.type);
    _startTicker();
  }

  Future<void> _skipCurrentPhase() async {
    if (_completed || _awaitingNextExercise || _isTransitioning) {
      return;
    }
    await _playTransitionCue();
    await _finishCurrentPhase(skipped: true);
  }

  void _adjustRestSeconds(int delta) {
    if (_completed || _awaitingNextExercise) {
      return;
    }
    if (_activePhaseType != GuidedPhaseType.rest) {
      return;
    }

    final nextValue = _maxInt(1, _remainingSeconds + delta);
    setState(() {
      _remainingSeconds = nextValue;
    });
  }

  Future<bool> _confirmStopSession() async {
    final decision = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stop guided session?'),
          content: const Text(
            'You can return and save partial notes, but the guided timer run will end now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep going'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Stop session'),
            ),
          ],
        );
      },
    );

    return decision ?? false;
  }

  GuidedSessionResult _buildResult({required bool aborted}) {
    final completedExercises = _completed
        ? _totalExerciseCount
        : _awaitingNextExercise
        ? _currentExerciseIndex + 1
        : _inWarmup
        ? 0
        : _currentExerciseIndex;

    return GuidedSessionResult(
      completed: _completed && !aborted,
      aborted: aborted,
      plannedTotalSeconds: widget.plannedTotalSeconds,
      elapsedSeconds: _elapsedSeconds,
      completedExercises: completedExercises,
      totalExercises: _totalExerciseCount,
      completedPhases: _completedPhases,
      totalPhases: _totalPhaseCount,
      skippedPhases: _skippedPhases,
      finishedAt: DateTime.now(),
    );
  }

  void _closeWithResult({required bool aborted}) {
    if (_didPop || !mounted) {
      return;
    }

    _didPop = true;
    _ticker?.cancel();
    Navigator.of(context).pop(_buildResult(aborted: aborted));
  }

  Future<void> _handleBackRequest() async {
    if (_completed) {
      _closeWithResult(aborted: false);
      return;
    }

    final shouldStop = await _confirmStopSession();
    if (shouldStop) {
      _closeWithResult(aborted: true);
    }
  }

  Future<void> _playPhaseCue(GuidedPhaseType type) async {
    switch (type) {
      case GuidedPhaseType.work:
        await SystemSound.play(SystemSoundType.click);
      case GuidedPhaseType.rest:
        await SystemSound.play(SystemSoundType.alert);
      case GuidedPhaseType.core:
        await SystemSound.play(SystemSoundType.click);
        await Future<void>.delayed(const Duration(milliseconds: 130));
        await SystemSound.play(SystemSoundType.click);
      case GuidedPhaseType.warmup:
        await SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> _playTransitionCue() async {
    await SystemSound.play(SystemSoundType.alert);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> _playCompletionCue() async {
    await SystemSound.play(SystemSoundType.alert);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await SystemSound.play(SystemSoundType.alert);
  }

  String _formatSeconds(int value) {
    final minutes = value ~/ 60;
    final seconds = value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _phaseProgressValue() {
    if (_inWarmup) {
      final total = widget.warmupSeconds;
      if (total <= 0) {
        return 1;
      }
      return ((total - _remainingSeconds) / total).clamp(0, 1);
    }

    final total = _currentPhase.durationSeconds;
    if (total <= 0) {
      return 1;
    }
    return ((total - _remainingSeconds) / total).clamp(0, 1);
  }

  double _workoutProgressValue() {
    if (_totalPhaseCount <= 0) {
      return 1;
    }

    var completedUnits = (_completedPhases + _skippedPhases).toDouble();
    if (!_completed && !_awaitingNextExercise) {
      final total = _activePhaseTotalSeconds;
      if (total > 0) {
        completedUnits += ((total - _remainingSeconds) / total).clamp(0.0, 1.0);
      }
    }

    return (completedUnits / _totalPhaseCount).clamp(0.0, 1.0);
  }

  _PhaseStyle _phaseStyle(BuildContext context, GuidedPhaseType phaseType) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    switch (phaseType) {
      case GuidedPhaseType.warmup:
        return _PhaseStyle(
          label: 'Warm-up',
          icon: Icons.local_fire_department,
          color: Colors.orange,
          tint: Colors.orange.withValues(alpha: 0.16),
        );
      case GuidedPhaseType.work:
        return _PhaseStyle(
          label: 'Work',
          icon: Icons.fitness_center,
          color: scheme.primary,
          tint: scheme.primary.withValues(alpha: 0.12),
        );
      case GuidedPhaseType.rest:
        return _PhaseStyle(
          label: 'Rest',
          icon: Icons.spa,
          color: scheme.secondary,
          tint: scheme.secondary.withValues(alpha: 0.14),
        );
      case GuidedPhaseType.core:
        return _PhaseStyle(
          label: 'Core',
          icon: Icons.bolt,
          color: Colors.teal,
          tint: Colors.teal.withValues(alpha: 0.14),
        );
    }
  }

  String? _nextPhaseLabel() {
    if (_inWarmup) {
      return _currentPhase.label;
    }

    final current = _currentExercise;
    if (_currentPhaseIndex < current.phases.length - 1) {
      return current.phases[_currentPhaseIndex + 1].label;
    }

    if (_currentExerciseIndex < _totalExerciseCount - 1) {
      return 'Next exercise: ${widget.exercises[_currentExerciseIndex + 1].name}';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Guided session')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No guided phases were generated.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _closeWithResult(aborted: true),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final phaseStyle = _phaseStyle(context, _activePhaseType);
    final exerciseTitle = _inWarmup ? 'Warm-up' : _currentExercise.name;
    final progressPct = (_workoutProgressValue() * 100).round();
    final nextPhase = _nextPhaseLabel();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        unawaited(_handleBackRequest());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Guided session')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.sessionType.label} coach mode',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _completed
                    ? 'Session complete. Review and return to save.'
                    : _awaitingNextExercise
                    ? 'Exercise complete. Confirm when you are ready for the next one.'
                    : 'Exercise ${_currentExerciseIndex + 1}/$_totalExerciseCount: $exerciseTitle',
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _workoutProgressValue()),
              const SizedBox(height: 4),
              Text(
                '$progressPct% complete',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 14),
              Card(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: phaseStyle.tint,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            avatar: Icon(phaseStyle.icon, size: 18),
                            label: Text(phaseStyle.label),
                          ),
                          if (_running && !_completed)
                            const Chip(label: Text('Live')),
                          if (_awaitingNextExercise)
                            const Chip(label: Text('Waiting for next')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _formatSeconds(_remainingSeconds),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: phaseStyle.color,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _phaseProgressValue()),
                      const SizedBox(height: 10),
                      if (nextPhase != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.upcoming,
                              size: 18,
                              color: phaseStyle.color,
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text('Next: $nextPhase')),
                          ],
                        ),
                      if (_activePhaseType == GuidedPhaseType.rest &&
                          !_completed &&
                          !_awaitingNextExercise) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _adjustRestSeconds(-10),
                              icon: const Icon(Icons.remove),
                              label: const Text('Rest -10s'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _adjustRestSeconds(10),
                              icon: const Icon(Icons.add),
                              label: const Text('Rest +10s'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: (_completed || _awaitingNextExercise)
                                ? null
                                : _togglePause,
                            icon: Icon(
                              _running ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(_running ? 'Pause' : 'Resume'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (_completed || _awaitingNextExercise)
                                ? null
                                : _skipCurrentPhase,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Skip phase'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _completed
                                ? null
                                : () async {
                                    _pause();
                                    final shouldStop =
                                        await _confirmStopSession();
                                    if (shouldStop) {
                                      _closeWithResult(aborted: true);
                                    } else if (mounted &&
                                        !_awaitingNextExercise) {
                                      _startTicker();
                                    }
                                  },
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop timer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_awaitingNextExercise) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transition',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Up next: ${widget.exercises[_currentExerciseIndex + 1].name}',
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _startNextExercise,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start next exercise'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_completed) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Great work. Elapsed ${_formatSeconds(_elapsedSeconds)} with $_skippedPhases skipped phases.',
                          ),
                        ),
                        FilledButton(
                          onPressed: () => _closeWithResult(aborted: false),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: widget.exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = widget.exercises[index];
                      final isCurrent =
                          !_completed &&
                          (index == _currentExerciseIndex ||
                              (_inWarmup && index == 0));
                      final isDone =
                          index < _currentExerciseIndex || _completed;
                      final trailing = _formatSeconds(
                        _exerciseDurationSeconds(exercise),
                      );

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isDone
                              ? Icons.check_circle
                              : isCurrent
                              ? Icons.play_circle
                              : Icons.radio_button_unchecked,
                        ),
                        title: Text(exercise.name),
                        subtitle: Text(
                          '${exercise.phases.length} timed phases',
                        ),
                        trailing: Text(trailing),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseStyle {
  const _PhaseStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color tint;
}
