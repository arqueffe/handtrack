import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_track/features/sessions/application/session_providers.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';
import 'package:hand_track/features/sessions/presentation/guided_timer_screen.dart';

const _coreMovementOptions = <String>[
  'Hollow body',
  'Fore arm plank',
  'Dead bug',
  'Fore arm plank rock',
  'C curve',
  'Leg raise',
  'Hip dip',
];

const _recordableSessionTypes = <SessionType>[
  SessionType.strength,
  SessionType.endurance,
];

class SessionFlowScreen extends ConsumerStatefulWidget {
  const SessionFlowScreen({super.key, this.initialSessionType});

  final SessionType? initialSessionType;

  @override
  ConsumerState<SessionFlowScreen> createState() => _SessionFlowScreenState();
}

class _SessionFlowScreenState extends ConsumerState<SessionFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  int _prefillEpoch = 0;

  int _maxInt(int a, int b) => a > b ? a : b;
  int _minInt(int a, int b) => a < b ? a : b;
  bool _isRecordableSessionType(SessionType type) =>
      _recordableSessionTypes.contains(type);
  bool _isGuidedCompatibleSessionType(SessionType type) =>
      _isRecordableSessionType(type);
  SessionType _sanitizeRecordableSessionType(SessionType? type) {
    if (type != null && _isRecordableSessionType(type)) {
      return type;
    }
    return SessionType.strength;
  }

  SessionType _sessionType = SessionType.strength;
  DateTime _debugSessionDate = DateTime.now();
  int _fatigue = 5;
  int _fingerSensitivity = 5;

  final _strengthWarmupController = TextEditingController(text: '12');
  final _strengthMaxHangSetsController = TextEditingController(text: '3');
  final _strengthMaxHangRepsController = TextEditingController(text: '3');
  final _strengthHangSecondsController = TextEditingController(text: '7');
  final _strengthRestSecondsController = TextEditingController(text: '180');
  final _strengthEdgeController = TextEditingController(text: '20');
  final _strengthAddedKgController = TextEditingController(text: '0');
  int _strengthHangRpe = 7;
  final _strengthPullupSetsController = TextEditingController(text: '3');
  final _strengthPullupRepsController = TextEditingController(text: '3');
  final _strengthPullupRestSecondsController = TextEditingController(
    text: '180',
  );
  final _strengthPullupLoadController = TextEditingController(text: '0');
  int _strengthPullupRpe = 7;
  bool _strengthLockOffPerformed = false;
  final _strengthLockOffSetsController = TextEditingController(text: '2');
  final _strengthLockOff90SecondsController = TextEditingController(text: '5');
  final _strengthLockOff120SecondsController = TextEditingController(text: '5');

  final _enduranceWarmupController = TextEditingController(text: '12');
  EnduranceProtocol _enduranceProtocol = EnduranceProtocol.repeaters;
  final _enduranceRoundsController = TextEditingController(text: '6');
  final _enduranceWorkSecondsController = TextEditingController(text: '7');
  final _enduranceRestSecondsController = TextEditingController(text: '3');
  final _enduranceSetRestSecondsController = TextEditingController(text: '90');
  final _enduranceSetsController = TextEditingController(text: '3');
  final _enduranceEdgeController = TextEditingController(text: '20');
  final _enduranceAddedKgController = TextEditingController(text: '0');
  int _enduranceRpe = 7;
  bool _enduranceRecoveringWell = false;
  bool _enduranceSmallHoldPullupsPerformed = false;
  final _endurancePullupSetsController = TextEditingController(text: '2');
  final _endurancePullupRepsController = TextEditingController(text: '4');
  int _endurancePullupRpe = 7;

  String _selectedCoreMovement = _coreMovementOptions.first;
  final _coreDurationController = TextEditingController(text: '30');
  final List<CoreMoment> _coreMoments = [];

  final _notesController = TextEditingController();
  GuidedSessionResult? _guidedSessionResult;

  @override
  void initState() {
    super.initState();
    _sessionType = _sanitizeRecordableSessionType(widget.initialSessionType);
    unawaited(_prefillFromLatest(_sessionType));
  }

  @override
  void dispose() {
    _strengthWarmupController.dispose();
    _strengthMaxHangSetsController.dispose();
    _strengthMaxHangRepsController.dispose();
    _strengthHangSecondsController.dispose();
    _strengthRestSecondsController.dispose();
    _strengthEdgeController.dispose();
    _strengthAddedKgController.dispose();
    _strengthPullupSetsController.dispose();
    _strengthPullupRepsController.dispose();
    _strengthPullupRestSecondsController.dispose();
    _strengthPullupLoadController.dispose();
    _strengthLockOffSetsController.dispose();
    _strengthLockOff90SecondsController.dispose();
    _strengthLockOff120SecondsController.dispose();

    _enduranceWarmupController.dispose();
    _enduranceRoundsController.dispose();
    _enduranceWorkSecondsController.dispose();
    _enduranceRestSecondsController.dispose();
    _enduranceSetRestSecondsController.dispose();
    _enduranceSetsController.dispose();
    _enduranceEdgeController.dispose();
    _enduranceAddedKgController.dispose();
    _endurancePullupSetsController.dispose();
    _endurancePullupRepsController.dispose();

    _coreDurationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _parseInt(TextEditingController controller, {int fallback = 0}) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  double _parseDouble(TextEditingController controller, {double fallback = 0}) {
    return double.tryParse(controller.text.trim()) ?? fallback;
  }

  String _formatDurationSeconds(int value) {
    final safe = value < 0 ? 0 : value;
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String? _validateIntRange(
    String? value, {
    required int min,
    required int max,
    required String label,
  }) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) {
      return '$label must be a number';
    }
    if (parsed < min || parsed > max) {
      return '$label must be $min-$max';
    }
    return null;
  }

  Future<void> _prefillFromLatest(SessionType type) async {
    final epoch = ++_prefillEpoch;
    final latest = await ref
        .read(sessionRepositoryProvider)
        .latestSessionByType(type);

    if (!mounted || epoch != _prefillEpoch || latest == null) {
      return;
    }

    setState(() {
      _fatigue = latest.bodyState.fatigue;
      _fingerSensitivity = latest.bodyState.fingerSensitivity;
      _notesController.text = latest.notes;
      _coreMoments
        ..clear()
        ..addAll(latest.coreMoments);

      final strength = latest.strengthDetails;
      if (strength != null) {
        _strengthWarmupController.text = strength.warmupMinutes.toString();
        _strengthMaxHangSetsController.text = strength.maxHangSets.toString();
        _strengthMaxHangRepsController.text = strength.maxHangReps.toString();
        _strengthHangSecondsController.text = strength.hangSeconds.toString();
        _strengthRestSecondsController.text = strength.restSeconds.toString();
        _strengthEdgeController.text = strength.edgeMm.toString();
        _strengthAddedKgController.text = strength.addedKg.toString();
        _strengthHangRpe = strength.hangRpe;
        _strengthPullupSetsController.text = strength.weightedPullupSets
            .toString();
        _strengthPullupRepsController.text = strength.weightedPullupReps
            .toString();
        _strengthPullupRestSecondsController.text = strength
            .weightedPullupRestSeconds
            .toString();
        _strengthPullupLoadController.text = strength.weightedPullupLoadKg
            .toString();
        _strengthPullupRpe = strength.weightedPullupRpe;
        _strengthLockOffPerformed = strength.lockOffPerformed;
        _strengthLockOffSetsController.text = strength.lockOffSets.toString();
        _strengthLockOff90SecondsController.text = strength.lockOff90Seconds
            .toString();
        _strengthLockOff120SecondsController.text = strength.lockOff120Seconds
            .toString();
      }

      final endurance = latest.enduranceDetails;
      if (endurance != null) {
        _enduranceWarmupController.text = endurance.warmupMinutes.toString();
        _enduranceProtocol = endurance.protocol;
        _enduranceRoundsController.text = endurance.rounds.toString();
        _enduranceWorkSecondsController.text = endurance.workSeconds.toString();
        _enduranceRestSecondsController.text = endurance.restSeconds.toString();
        _enduranceSetRestSecondsController.text = endurance.setRestSeconds
            .toString();
        _enduranceSetsController.text = endurance.sets.toString();
        _enduranceEdgeController.text = endurance.edgeMm.toString();
        _enduranceAddedKgController.text = endurance.addedKg.toString();
        _enduranceRpe = endurance.rpe;
        _enduranceRecoveringWell = endurance.recoveringWell;
        _enduranceSmallHoldPullupsPerformed =
            endurance.smallHoldPullupsPerformed;
        _endurancePullupSetsController.text = endurance.smallHoldPullupSets
            .toString();
        _endurancePullupRepsController.text = endurance.smallHoldPullupReps
            .toString();
        _endurancePullupRpe = endurance.smallHoldPullupRpe;
      }
    });
  }

  Future<void> _pickDebugSessionDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _debugSessionDate.isAfter(now) ? now : _debugSessionDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Debug session date override',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _debugSessionDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        _debugSessionDate.hour,
        _debugSessionDate.minute,
      );
    });
  }

  Future<void> _startGuidedSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (_sessionType != SessionType.strength &&
        _sessionType != SessionType.endurance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Guided timer is available for Strength and Endurance sessions.',
          ),
        ),
      );
      return;
    }

    final exercises = _sessionType == SessionType.strength
        ? _buildStrengthExercises()
        : _buildEnduranceExercises();

    final warmupSeconds = _sessionType == SessionType.strength
        ? _parseInt(_strengthWarmupController, fallback: 12) * 60
        : _parseInt(_enduranceWarmupController, fallback: 12) * 60;

    final launchData = _buildGuidedLaunchData(
      exercises: exercises,
      warmupSeconds: warmupSeconds,
    );

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No timed phases available for this setup.'),
        ),
      );
      return;
    }

    final shouldStart = await _showGuidedPreflight(launchData);
    if (!shouldStart || !mounted) {
      return;
    }

    final result = await Navigator.of(context).push<GuidedSessionResult>(
      MaterialPageRoute<GuidedSessionResult>(
        builder: (_) => GuidedSessionTimerScreen(
          sessionType: _sessionType,
          warmupSeconds: warmupSeconds,
          plannedTotalSeconds: launchData.totalSeconds,
          exercises: exercises,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    await _applyGuidedResult(result);
  }

  _GuidedLaunchData _buildGuidedLaunchData({
    required List<GuidedTimerExercise> exercises,
    required int warmupSeconds,
  }) {
    var totalSeconds = warmupSeconds;
    var totalPhases = warmupSeconds > 0 ? 1 : 0;
    var corePhases = 0;
    final summaries = <_GuidedExerciseSummary>[];

    for (final exercise in exercises) {
      var exerciseSeconds = 0;
      for (final phase in exercise.phases) {
        exerciseSeconds += phase.durationSeconds;
        if (phase.type == GuidedPhaseType.core) {
          corePhases += 1;
        }
      }

      totalSeconds += exerciseSeconds;
      totalPhases += exercise.phases.length;
      summaries.add(
        _GuidedExerciseSummary(
          name: exercise.name,
          seconds: exerciseSeconds,
          phaseCount: exercise.phases.length,
        ),
      );
    }

    return _GuidedLaunchData(
      warmupSeconds: warmupSeconds,
      totalSeconds: totalSeconds,
      totalPhases: totalPhases,
      corePhases: corePhases,
      exercises: summaries,
    );
  }

  Future<bool> _showGuidedPreflight(_GuidedLaunchData launchData) async {
    final decision = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ready to start coach mode?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This guided timer will run your workout flow with automatic phase transitions and manual confirmation between exercises.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.timer),
                        label: Text(
                          'Est. ${_formatDurationSeconds(launchData.totalSeconds)}',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.fitness_center),
                        label: Text('${launchData.exercises.length} exercises'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.route),
                        label: Text('${launchData.totalPhases} phases'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.bolt),
                        label: Text('${launchData.corePhases} core inserts'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Plan preview',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (launchData.warmupSeconds > 0) ...[
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.local_fire_department),
                              title: const Text('Warm-up'),
                              subtitle: const Text('Starts first'),
                              trailing: Text(
                                _formatDurationSeconds(
                                  launchData.warmupSeconds,
                                ),
                              ),
                            ),
                          ],
                          for (final summary in launchData.exercises)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.play_circle_outline),
                              title: Text(summary.name),
                              subtitle: Text(
                                '${summary.phaseCount} timed phases',
                              ),
                              trailing: Text(
                                _formatDurationSeconds(summary.seconds),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(true),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return decision ?? false;
  }

  Future<void> _applyGuidedResult(GuidedSessionResult result) async {
    final summaryLine = result.completed
        ? 'Guided timer completed ${result.completedExercises}/${result.totalExercises} exercises in ${_formatDurationSeconds(result.elapsedSeconds)}. Skipped phases: ${result.skippedPhases}.'
        : 'Guided timer stopped at ${_formatDurationSeconds(result.elapsedSeconds)} with ${result.completedExercises}/${result.totalExercises} exercises completed.';

    setState(() {
      _guidedSessionResult = result;
      if (_notesController.text.trim().isEmpty) {
        _notesController.text = summaryLine;
      } else {
        _notesController.text = '${_notesController.text.trim()}\n$summaryLine';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.completed
              ? 'Guided run complete. Review and save your session.'
              : 'Guided run stopped. You can still save your notes.',
        ),
      ),
    );

    await _askPostGuidedSessionRpe(result);
  }

  Future<void> _askPostGuidedSessionRpe(GuidedSessionResult result) async {
    if (!mounted || result.elapsedSeconds <= 0) {
      return;
    }

    String primaryLabel;
    int primaryRpe;
    String? secondaryLabel;
    int? secondaryRpe;

    if (_sessionType == SessionType.strength) {
      primaryLabel = 'Max hang RPE';
      primaryRpe = _strengthHangRpe;
      secondaryLabel = 'Weighted pull-up RPE';
      secondaryRpe = _strengthPullupRpe;
    } else {
      primaryLabel = 'Endurance RPE';
      primaryRpe = _enduranceRpe;
      if (_enduranceRecoveringWell && _enduranceSmallHoldPullupsPerformed) {
        secondaryLabel = 'Small-hold pull-up RPE';
        secondaryRpe = _endurancePullupRpe;
      }
    }

    final shouldApply = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('How hard was that session?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$primaryLabel: $primaryRpe/10'),
                    Slider(
                      value: primaryRpe.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$primaryRpe',
                      onChanged: (value) {
                        setDialogState(() {
                          primaryRpe = value.round();
                        });
                      },
                    ),
                    if (secondaryLabel != null && secondaryRpe != null) ...[
                      const SizedBox(height: 8),
                      Text('$secondaryLabel: $secondaryRpe/10'),
                      Slider(
                        value: secondaryRpe!.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$secondaryRpe',
                        onChanged: (value) {
                          setDialogState(() {
                            secondaryRpe = value.round();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Skip'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save RPE'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldApply != true || !mounted) {
      return;
    }

    setState(() {
      if (_sessionType == SessionType.strength) {
        _strengthHangRpe = primaryRpe;
        if (secondaryRpe != null) {
          _strengthPullupRpe = secondaryRpe!;
        }
      } else {
        _enduranceRpe = primaryRpe;
        if (secondaryRpe != null) {
          _endurancePullupRpe = secondaryRpe!;
        }
      }
    });
  }

  List<GuidedTimerExercise> _buildStrengthExercises() {
    var coreRotation = 0;
    final exercises = <GuidedTimerExercise>[];

    final hangSets = _parseInt(_strengthMaxHangSetsController, fallback: 3);
    final hangReps = _parseInt(_strengthMaxHangRepsController, fallback: 3);
    final hangSeconds = _parseInt(_strengthHangSecondsController, fallback: 7);
    final restSeconds = _parseInt(
      _strengthRestSecondsController,
      fallback: 180,
    );

    final maxHangPhases = <GuidedTimerPhase>[];
    for (var set = 1; set <= hangSets; set++) {
      final workSeconds = _maxInt(1, hangSeconds * _maxInt(1, hangReps));
      maxHangPhases.add(
        GuidedTimerPhase(
          label: 'Max hang set $set',
          durationSeconds: workSeconds,
          type: GuidedPhaseType.work,
        ),
      );

      if (set < hangSets) {
        coreRotation = _appendRestWithOptionalCore(
          phases: maxHangPhases,
          restSeconds: restSeconds,
          coreRotation: coreRotation,
          restLabel: 'Rest after set $set',
        );
      }
    }

    exercises.add(
      GuidedTimerExercise(name: 'Max hangs', phases: maxHangPhases),
    );

    final pullSets = _parseInt(_strengthPullupSetsController, fallback: 3);
    final pullReps = _parseInt(_strengthPullupRepsController, fallback: 3);
    final pullRestSeconds = _parseInt(
      _strengthPullupRestSecondsController,
      fallback: 180,
    );
    final pullPhases = <GuidedTimerPhase>[];
    for (var set = 1; set <= pullSets; set++) {
      final workSeconds = _maxInt(1, pullReps * 6);
      pullPhases.add(
        GuidedTimerPhase(
          label: 'Weighted pull-up set $set',
          durationSeconds: workSeconds,
          type: GuidedPhaseType.work,
        ),
      );

      if (set < pullSets) {
        coreRotation = _appendRestWithOptionalCore(
          phases: pullPhases,
          restSeconds: pullRestSeconds,
          coreRotation: coreRotation,
          restLabel: 'Rest after set $set',
        );
      }
    }

    exercises.add(
      GuidedTimerExercise(name: 'Weighted pull-ups', phases: pullPhases),
    );

    if (_strengthLockOffPerformed) {
      final lockSets = _parseInt(_strengthLockOffSetsController, fallback: 2);
      final lock90 = _parseInt(
        _strengthLockOff90SecondsController,
        fallback: 5,
      );
      final lock120 = _parseInt(
        _strengthLockOff120SecondsController,
        fallback: 5,
      );

      final lockPhases = <GuidedTimerPhase>[];
      for (var set = 1; set <= lockSets; set++) {
        lockPhases.add(
          GuidedTimerPhase(
            label: 'Lock-off set $set (90 + 120)',
            durationSeconds: _maxInt(1, lock90 + lock120),
            type: GuidedPhaseType.work,
          ),
        );

        if (set < lockSets) {
          coreRotation = _appendRestWithOptionalCore(
            phases: lockPhases,
            restSeconds: restSeconds,
            coreRotation: coreRotation,
            restLabel: 'Rest after lock-off set $set',
          );
        }
      }

      exercises.add(GuidedTimerExercise(name: 'Lock-offs', phases: lockPhases));
    }

    return exercises.where((item) => item.phases.isNotEmpty).toList();
  }

  List<GuidedTimerExercise> _buildEnduranceExercises() {
    var coreRotation = 0;
    final exercises = <GuidedTimerExercise>[];

    final rounds = _parseInt(_enduranceRoundsController, fallback: 6);
    final sets = _parseInt(_enduranceSetsController, fallback: 3);
    final onSeconds = _parseInt(_enduranceWorkSecondsController, fallback: 7);
    final offSeconds = _parseInt(_enduranceRestSecondsController, fallback: 3);
    final setRestSeconds = _parseInt(
      _enduranceSetRestSecondsController,
      fallback: 90,
    );

    final repeaterPhases = <GuidedTimerPhase>[];
    for (var set = 1; set <= sets; set++) {
      for (var round = 1; round <= rounds; round++) {
        repeaterPhases.add(
          GuidedTimerPhase(
            label: 'Set $set, round $round: On',
            durationSeconds: _maxInt(1, onSeconds),
            type: GuidedPhaseType.work,
          ),
        );

        final isLastRoundInSet = round == rounds;
        final isLastSet = set == sets;
        if (isLastRoundInSet && isLastSet) {
          continue;
        }

        if (!isLastRoundInSet) {
          repeaterPhases.add(
            GuidedTimerPhase(
              label: 'Off',
              durationSeconds: _maxInt(1, offSeconds),
              type: GuidedPhaseType.rest,
            ),
          );
          continue;
        }

        final betweenSetsSeconds =
            _enduranceProtocol == EnduranceProtocol.repeaters
            ? setRestSeconds
            : offSeconds;

        coreRotation = _appendRestWithOptionalCore(
          phases: repeaterPhases,
          restSeconds: betweenSetsSeconds,
          coreRotation: coreRotation,
          restLabel: _enduranceProtocol == EnduranceProtocol.repeaters
              ? 'Rest between sets'
              : 'Off',
        );
      }
    }

    final enduranceName = _enduranceProtocol == EnduranceProtocol.repeaters
        ? 'Repeaters'
        : 'Intermittent hangs';
    exercises.add(
      GuidedTimerExercise(name: enduranceName, phases: repeaterPhases),
    );

    if (_enduranceRecoveringWell && _enduranceSmallHoldPullupsPerformed) {
      final pullSets = _parseInt(_endurancePullupSetsController, fallback: 2);
      final pullReps = _parseInt(_endurancePullupRepsController, fallback: 4);
      final smallHoldPhases = <GuidedTimerPhase>[];
      for (var set = 1; set <= pullSets; set++) {
        smallHoldPhases.add(
          GuidedTimerPhase(
            label: 'Small-hold pull-up set $set',
            durationSeconds: _maxInt(1, pullReps * 6),
            type: GuidedPhaseType.work,
          ),
        );

        if (set < pullSets) {
          coreRotation = _appendRestWithOptionalCore(
            phases: smallHoldPhases,
            restSeconds: _maxInt(10, offSeconds * 6),
            coreRotation: coreRotation,
            restLabel: 'Rest after set $set',
          );
        }
      }

      exercises.add(
        GuidedTimerExercise(
          name: 'Small-hold pull-ups',
          phases: smallHoldPhases,
        ),
      );
    }

    return exercises.where((item) => item.phases.isNotEmpty).toList();
  }

  int _appendRestWithOptionalCore({
    required List<GuidedTimerPhase> phases,
    required int restSeconds,
    required int coreRotation,
    required String restLabel,
  }) {
    final safeRest = _maxInt(1, restSeconds);
    if (_coreMoments.isEmpty) {
      phases.add(
        GuidedTimerPhase(
          label: restLabel,
          durationSeconds: safeRest,
          type: GuidedPhaseType.rest,
        ),
      );
      return coreRotation;
    }

    final core = _coreMoments[coreRotation % _coreMoments.length];
    final coreSeconds = _maxInt(1, _minInt(core.durationSeconds, safeRest));
    final pre = (safeRest - coreSeconds) ~/ 2;
    final post = safeRest - coreSeconds - pre;

    if (pre > 0) {
      phases.add(
        GuidedTimerPhase(
          label: '$restLabel (pre-core)',
          durationSeconds: pre,
          type: GuidedPhaseType.rest,
        ),
      );
    }

    phases.add(
      GuidedTimerPhase(
        label: 'Core: ${core.name}',
        durationSeconds: coreSeconds,
        type: GuidedPhaseType.core,
      ),
    );

    if (post > 0) {
      phases.add(
        GuidedTimerPhase(
          label: '$restLabel (post-core)',
          durationSeconds: post,
          type: GuidedPhaseType.rest,
        ),
      );
    }

    return coreRotation + 1;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FingerLog? finger;
    PullingLog? pulling;
    StrengthSessionDetails? strengthDetails;
    EnduranceSessionDetails? enduranceDetails;

    switch (_sessionType) {
      case SessionType.strength:
        strengthDetails = StrengthSessionDetails(
          warmupMinutes: _parseInt(_strengthWarmupController, fallback: 12),
          maxHangSets: _parseInt(_strengthMaxHangSetsController, fallback: 3),
          maxHangReps: _parseInt(_strengthMaxHangRepsController, fallback: 3),
          hangSeconds: _parseInt(_strengthHangSecondsController, fallback: 7),
          restSeconds: _parseInt(_strengthRestSecondsController, fallback: 180),
          edgeMm: _parseInt(_strengthEdgeController, fallback: 20),
          addedKg: _parseDouble(_strengthAddedKgController),
          hangRpe: _strengthHangRpe,
          weightedPullupSets: _parseInt(
            _strengthPullupSetsController,
            fallback: 3,
          ),
          weightedPullupReps: _parseInt(
            _strengthPullupRepsController,
            fallback: 3,
          ),
          weightedPullupRestSeconds: _parseInt(
            _strengthPullupRestSecondsController,
            fallback: 180,
          ),
          weightedPullupLoadKg: _parseDouble(_strengthPullupLoadController),
          weightedPullupRpe: _strengthPullupRpe,
          lockOffSets: _strengthLockOffPerformed
              ? _parseInt(_strengthLockOffSetsController, fallback: 2)
              : 0,
          lockOff90Seconds: _strengthLockOffPerformed
              ? _parseInt(_strengthLockOff90SecondsController, fallback: 5)
              : 0,
          lockOff120Seconds: _strengthLockOffPerformed
              ? _parseInt(_strengthLockOff120SecondsController, fallback: 5)
              : 0,
          lockOffPerformed: _strengthLockOffPerformed,
        );

        finger = FingerLog(
          edgeMm: strengthDetails.edgeMm,
          addedKg: strengthDetails.addedKg,
          rpe: strengthDetails.hangRpe,
          cleanExecution: true,
        );
        pulling = PullingLog(
          loadKg: strengthDetails.weightedPullupLoadKg,
          reps: strengthDetails.weightedPullupReps,
          rpe: strengthDetails.weightedPullupRpe,
        );
        break;

      case SessionType.endurance:
        enduranceDetails = EnduranceSessionDetails(
          warmupMinutes: _parseInt(_enduranceWarmupController, fallback: 12),
          protocol: _enduranceProtocol,
          rounds: _parseInt(_enduranceRoundsController, fallback: 6),
          workSeconds: _parseInt(_enduranceWorkSecondsController, fallback: 7),
          restSeconds: _parseInt(_enduranceRestSecondsController, fallback: 3),
          setRestSeconds: _parseInt(
            _enduranceSetRestSecondsController,
            fallback: 90,
          ),
          sets: _parseInt(_enduranceSetsController, fallback: 3),
          edgeMm: _parseInt(_enduranceEdgeController, fallback: 20),
          addedKg: _parseDouble(_enduranceAddedKgController),
          rpe: _enduranceRpe,
          recoveringWell: _enduranceRecoveringWell,
          smallHoldPullupsPerformed:
              _enduranceRecoveringWell && _enduranceSmallHoldPullupsPerformed,
          smallHoldPullupSets:
              _enduranceRecoveringWell && _enduranceSmallHoldPullupsPerformed
              ? _parseInt(_endurancePullupSetsController, fallback: 2)
              : 0,
          smallHoldPullupReps:
              _enduranceRecoveringWell && _enduranceSmallHoldPullupsPerformed
              ? _parseInt(_endurancePullupRepsController, fallback: 4)
              : 0,
          smallHoldPullupRpe: _endurancePullupRpe,
        );

        finger = FingerLog(
          edgeMm: enduranceDetails.edgeMm,
          addedKg: enduranceDetails.addedKg,
          rpe: enduranceDetails.rpe,
          cleanExecution: true,
        );

        if (enduranceDetails.smallHoldPullupsPerformed) {
          pulling = PullingLog(
            loadKg: 0,
            reps:
                enduranceDetails.smallHoldPullupSets *
                enduranceDetails.smallHoldPullupReps,
            rpe: enduranceDetails.smallHoldPullupRpe,
          );
        }
        break;

      case SessionType.climbing:
      case SessionType.recovery:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Only Strength and Endurance sessions are recordable.',
            ),
          ),
        );
        return;
    }

    final session = TrainingSession.create(
      sessionDate: kDebugMode ? _debugSessionDate : DateTime.now(),
      sessionType: _sessionType,
      bodyState: BodyState(
        fatigue: _fatigue,
        fingerSensitivity: _fingerSensitivity,
      ),
      finger: finger,
      pulling: pulling,
      strengthDetails: strengthDetails,
      enduranceDetails: enduranceDetails,
      coreMoments: List<CoreMoment>.from(_coreMoments),
      notes: _notesController.text.trim(),
    );

    await ref.read(sessionRepositoryProvider).saveSession(session);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Session saved locally')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s session')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session type',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SessionType>(
                      initialValue: _sessionType,
                      items: _recordableSessionTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _sessionType = _sanitizeRecordableSessionType(value);
                          _guidedSessionResult = null;
                        });
                        unawaited(_prefillFromLatest(value));
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Fatigue: $_fatigue/10'),
                    Slider(
                      value: _fatigue.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_fatigue',
                      onChanged: (value) {
                        setState(() => _fatigue = value.round());
                      },
                    ),
                    Text('Finger sensitivity: $_fingerSensitivity/10'),
                    Slider(
                      value: _fingerSensitivity.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_fingerSensitivity',
                      onChanged: (value) {
                        setState(() => _fingerSensitivity = value.round());
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug only: session date override',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Current date: ${_debugSessionDate.toLocal().toString().split('.').first}',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickDebugSessionDate,
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Pick date'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _debugSessionDate = DateTime.now();
                              });
                            },
                            child: const Text('Reset to now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.initialSessionType != null &&
                !_isRecordableSessionType(widget.initialSessionType!)) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Today\'s planned ${widget.initialSessionType!.label} session stays in weekly planning, but recordable sessions are Strength and Endurance.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_sessionType == SessionType.strength)
              _StrengthSection(
                warmupController: _strengthWarmupController,
                maxHangSetsController: _strengthMaxHangSetsController,
                maxHangRepsController: _strengthMaxHangRepsController,
                hangSecondsController: _strengthHangSecondsController,
                restSecondsController: _strengthRestSecondsController,
                edgeController: _strengthEdgeController,
                addedKgController: _strengthAddedKgController,
                hangRpe: _strengthHangRpe,
                onHangRpeChanged: (value) {
                  setState(() => _strengthHangRpe = value);
                },
                pullupSetsController: _strengthPullupSetsController,
                pullupRepsController: _strengthPullupRepsController,
                pullupRestSecondsController:
                    _strengthPullupRestSecondsController,
                pullupLoadController: _strengthPullupLoadController,
                pullupRpe: _strengthPullupRpe,
                onPullupRpeChanged: (value) {
                  setState(() => _strengthPullupRpe = value);
                },
                lockOffPerformed: _strengthLockOffPerformed,
                onLockOffPerformedChanged: (value) {
                  setState(() => _strengthLockOffPerformed = value);
                },
                lockOffSetsController: _strengthLockOffSetsController,
                lockOff90SecondsController: _strengthLockOff90SecondsController,
                lockOff120SecondsController:
                    _strengthLockOff120SecondsController,
                validateIntRange: _validateIntRange,
              ),
            if (_sessionType == SessionType.endurance)
              _EnduranceSection(
                warmupController: _enduranceWarmupController,
                protocol: _enduranceProtocol,
                onProtocolChanged: (value) {
                  setState(() => _enduranceProtocol = value);
                },
                roundsController: _enduranceRoundsController,
                workSecondsController: _enduranceWorkSecondsController,
                restSecondsController: _enduranceRestSecondsController,
                setRestSecondsController: _enduranceSetRestSecondsController,
                setsController: _enduranceSetsController,
                edgeController: _enduranceEdgeController,
                addedKgController: _enduranceAddedKgController,
                rpe: _enduranceRpe,
                onRpeChanged: (value) {
                  setState(() => _enduranceRpe = value);
                },
                recoveringWell: _enduranceRecoveringWell,
                onRecoveringWellChanged: (value) {
                  setState(() {
                    _enduranceRecoveringWell = value;
                    if (!value) {
                      _enduranceSmallHoldPullupsPerformed = false;
                    }
                  });
                },
                smallHoldPullupsPerformed: _enduranceSmallHoldPullupsPerformed,
                onSmallHoldPullupsChanged: (value) {
                  setState(() => _enduranceSmallHoldPullupsPerformed = value);
                },
                pullupSetsController: _endurancePullupSetsController,
                pullupRepsController: _endurancePullupRepsController,
                pullupRpe: _endurancePullupRpe,
                onPullupRpeChanged: (value) {
                  setState(() => _endurancePullupRpe = value);
                },
                validateIntRange: _validateIntRange,
              ),
            const SizedBox(height: 12),
            _CoreBlock(
              movementOptions: _coreMovementOptions,
              selectedMovement: _selectedCoreMovement,
              onMovementChanged: (value) {
                setState(() => _selectedCoreMovement = value);
              },
              coreDurationController: _coreDurationController,
              coreMoments: _coreMoments,
              onAddMoment: (moment) {
                setState(() => _coreMoments.add(moment));
              },
              onRemoveMoment: (index) {
                setState(() => _coreMoments.removeAt(index));
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'What happened today and how did your body respond?',
              ),
            ),
            if (_guidedSessionResult != null) ...[
              const SizedBox(height: 12),
              _GuidedResultCard(
                result: _guidedSessionResult!,
                formatDuration: _formatDurationSeconds,
              ),
            ],
            const SizedBox(height: 18),
            if (_isGuidedCompatibleSessionType(_sessionType)) ...[
              FilledButton(
                onPressed: _startGuidedSession,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _guidedSessionResult == null
                        ? 'Start session'
                        : 'Run guided session again',
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            FilledButton(
              onPressed: _save,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Save session'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StrengthSection extends StatelessWidget {
  const _StrengthSection({
    required this.warmupController,
    required this.maxHangSetsController,
    required this.maxHangRepsController,
    required this.hangSecondsController,
    required this.restSecondsController,
    required this.edgeController,
    required this.addedKgController,
    required this.hangRpe,
    required this.onHangRpeChanged,
    required this.pullupSetsController,
    required this.pullupRepsController,
    required this.pullupRestSecondsController,
    required this.pullupLoadController,
    required this.pullupRpe,
    required this.onPullupRpeChanged,
    required this.lockOffPerformed,
    required this.onLockOffPerformedChanged,
    required this.lockOffSetsController,
    required this.lockOff90SecondsController,
    required this.lockOff120SecondsController,
    required this.validateIntRange,
  });

  final TextEditingController warmupController;
  final TextEditingController maxHangSetsController;
  final TextEditingController maxHangRepsController;
  final TextEditingController hangSecondsController;
  final TextEditingController restSecondsController;
  final TextEditingController edgeController;
  final TextEditingController addedKgController;
  final int hangRpe;
  final ValueChanged<int> onHangRpeChanged;
  final TextEditingController pullupSetsController;
  final TextEditingController pullupRepsController;
  final TextEditingController pullupRestSecondsController;
  final TextEditingController pullupLoadController;
  final int pullupRpe;
  final ValueChanged<int> onPullupRpeChanged;
  final bool lockOffPerformed;
  final ValueChanged<bool> onLockOffPerformedChanged;
  final TextEditingController lockOffSetsController;
  final TextEditingController lockOff90SecondsController;
  final TextEditingController lockOff120SecondsController;
  final String? Function(
    String? value, {
    required int min,
    required int max,
    required String label,
  })
  validateIntRange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Strength session (strict template)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: warmupController,
              keyboardType: TextInputType.number,
              validator: (value) => validateIntRange(
                value,
                min: 10,
                max: 15,
                label: 'Warm-up minutes',
              ),
              decoration: const InputDecoration(
                labelText: 'Warm-up minutes (10-15)',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Max hangs: 3-5 sets x 3-5 reps of 5-10 sec hangs, 3 min rest',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: maxHangSetsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 3,
                      max: 5,
                      label: 'Max hang sets',
                    ),
                    decoration: const InputDecoration(labelText: 'Sets (3-5)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: maxHangRepsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 3,
                      max: 5,
                      label: 'Max hang reps',
                    ),
                    decoration: const InputDecoration(labelText: 'Reps (3-5)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: hangSecondsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 5,
                      max: 10,
                      label: 'Hang seconds',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Hang sec (5-10)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: restSecondsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 180,
                      max: 180,
                      label: 'Rest seconds',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Rest sec (180)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: edgeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edge mm'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: addedKgController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Added kg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Max hang RPE: $hangRpe/10'),
            Slider(
              value: hangRpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => onHangRpeChanged(value.round()),
            ),
            const Divider(height: 24),
            const Text('Weighted pull-ups: 3-5 sets x 3-5 reps'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: pullupSetsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 3,
                      max: 5,
                      label: 'Weighted pull-up sets',
                    ),
                    decoration: const InputDecoration(labelText: 'Sets (3-5)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: pullupRepsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 3,
                      max: 5,
                      label: 'Weighted pull-up reps',
                    ),
                    decoration: const InputDecoration(labelText: 'Reps (3-5)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: pullupLoadController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Weighted pull-up load kg',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: pullupRestSecondsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 60,
                      max: 300,
                      label: 'Weighted pull-up rest sec',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Rest sec (60-300)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Weighted pull-up RPE: $pullupRpe/10'),
            Slider(
              value: pullupRpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => onPullupRpeChanged(value.round()),
            ),
            const Divider(height: 24),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: lockOffPerformed,
              onChanged: (value) => onLockOffPerformedChanged(value ?? false),
              title: const Text('Optional lock-offs performed'),
              subtitle: const Text('2-3 sets of 5-10 sec at 90 and 120 deg'),
            ),
            if (lockOffPerformed) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: lockOffSetsController,
                      keyboardType: TextInputType.number,
                      validator: (value) => validateIntRange(
                        value,
                        min: 2,
                        max: 3,
                        label: 'Lock-off sets',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Sets (2-3)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: lockOff90SecondsController,
                      keyboardType: TextInputType.number,
                      validator: (value) => validateIntRange(
                        value,
                        min: 5,
                        max: 10,
                        label: '90 deg lock-off sec',
                      ),
                      decoration: const InputDecoration(
                        labelText: '90 deg sec (5-10)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: lockOff120SecondsController,
                keyboardType: TextInputType.number,
                validator: (value) => validateIntRange(
                  value,
                  min: 5,
                  max: 10,
                  label: '120 deg lock-off sec',
                ),
                decoration: const InputDecoration(
                  labelText: '120 deg sec (5-10)',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EnduranceSection extends StatelessWidget {
  const _EnduranceSection({
    required this.warmupController,
    required this.protocol,
    required this.onProtocolChanged,
    required this.roundsController,
    required this.workSecondsController,
    required this.restSecondsController,
    required this.setRestSecondsController,
    required this.setsController,
    required this.edgeController,
    required this.addedKgController,
    required this.rpe,
    required this.onRpeChanged,
    required this.recoveringWell,
    required this.onRecoveringWellChanged,
    required this.smallHoldPullupsPerformed,
    required this.onSmallHoldPullupsChanged,
    required this.pullupSetsController,
    required this.pullupRepsController,
    required this.pullupRpe,
    required this.onPullupRpeChanged,
    required this.validateIntRange,
  });

  final TextEditingController warmupController;
  final EnduranceProtocol protocol;
  final ValueChanged<EnduranceProtocol> onProtocolChanged;
  final TextEditingController roundsController;
  final TextEditingController workSecondsController;
  final TextEditingController restSecondsController;
  final TextEditingController setRestSecondsController;
  final TextEditingController setsController;
  final TextEditingController edgeController;
  final TextEditingController addedKgController;
  final int rpe;
  final ValueChanged<int> onRpeChanged;
  final bool recoveringWell;
  final ValueChanged<bool> onRecoveringWellChanged;
  final bool smallHoldPullupsPerformed;
  final ValueChanged<bool> onSmallHoldPullupsChanged;
  final TextEditingController pullupSetsController;
  final TextEditingController pullupRepsController;
  final int pullupRpe;
  final ValueChanged<int> onPullupRpeChanged;
  final String? Function(
    String? value, {
    required int min,
    required int max,
    required String label,
  })
  validateIntRange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Endurance / power-endurance (strict template)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: warmupController,
              keyboardType: TextInputType.number,
              validator: (value) => validateIntRange(
                value,
                min: 10,
                max: 15,
                label: 'Warm-up minutes',
              ),
              decoration: const InputDecoration(
                labelText: 'Warm-up minutes (10-15)',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<EnduranceProtocol>(
              initialValue: protocol,
              items: EnduranceProtocol.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item == EnduranceProtocol.repeaters
                            ? 'Repeaters'
                            : 'Intermittent hangs',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onProtocolChanged(value);
                }
              },
              decoration: const InputDecoration(labelText: 'Protocol'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: roundsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 6,
                      max: 10,
                      label: 'Rounds',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Rounds (6-10)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        validateIntRange(value, min: 3, max: 5, label: 'Sets'),
                    decoration: const InputDecoration(labelText: 'Sets (3-5)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: workSecondsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 7,
                      max: 10,
                      label: 'Work seconds',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'On sec (7-10)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: restSecondsController,
                    keyboardType: TextInputType.number,
                    validator: (value) => validateIntRange(
                      value,
                      min: 3,
                      max: 5,
                      label: 'Rest seconds',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Off sec (3-5)',
                    ),
                  ),
                ),
              ],
            ),
            if (protocol == EnduranceProtocol.repeaters) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: setRestSecondsController,
                keyboardType: TextInputType.number,
                validator: (value) => validateIntRange(
                  value,
                  min: 20,
                  max: 300,
                  label: 'Rest between sets seconds',
                ),
                decoration: const InputDecoration(
                  labelText: 'Rest between sets sec (20-300)',
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: edgeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edge mm'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: addedKgController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Added kg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Endurance RPE: $rpe/10'),
            Slider(
              value: rpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => onRpeChanged(value.round()),
            ),
            const Divider(height: 24),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: recoveringWell,
              onChanged: (value) => onRecoveringWellChanged(value ?? false),
              title: const Text('Recovering well today'),
              subtitle: const Text('Only then allow pull-ups on small holds.'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: smallHoldPullupsPerformed,
              onChanged: recoveringWell
                  ? (value) => onSmallHoldPullupsChanged(value ?? false)
                  : null,
              title: const Text('Performed pull-ups on small holds'),
            ),
            if (recoveringWell && smallHoldPullupsPerformed) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: pullupSetsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pull-up sets',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: pullupRepsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pull-up reps',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Small-hold pull-up RPE: $pullupRpe/10'),
              Slider(
                value: pullupRpe.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) => onPullupRpeChanged(value.round()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoreBlock extends StatelessWidget {
  const _CoreBlock({
    required this.movementOptions,
    required this.selectedMovement,
    required this.onMovementChanged,
    required this.coreDurationController,
    required this.coreMoments,
    required this.onAddMoment,
    required this.onRemoveMoment,
  });

  final List<String> movementOptions;
  final String selectedMovement;
  final ValueChanged<String> onMovementChanged;
  final TextEditingController coreDurationController;
  final List<CoreMoment> coreMoments;
  final ValueChanged<CoreMoment> onAddMoment;
  final ValueChanged<int> onRemoveMoment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Core movement moments (optional)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(selectedMovement),
                    initialValue: selectedMovement,
                    decoration: const InputDecoration(labelText: 'Movement'),
                    items: movementOptions
                        .map(
                          (movement) => DropdownMenuItem(
                            value: movement,
                            child: Text(movement),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onMovementChanged(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: coreDurationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sec'),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () {
                    final duration =
                        int.tryParse(coreDurationController.text) ?? 2;
                    onAddMoment(
                      CoreMoment(
                        name: selectedMovement,
                        durationSeconds: duration,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            if (coreMoments.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (var i = 0; i < coreMoments.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(coreMoments[i].name),
                  subtitle: Text('${coreMoments[i].durationSeconds} sec'),
                  trailing: IconButton(
                    onPressed: () => onRemoveMoment(i),
                    icon: const Icon(Icons.close),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuidedLaunchData {
  const _GuidedLaunchData({
    required this.warmupSeconds,
    required this.totalSeconds,
    required this.totalPhases,
    required this.corePhases,
    required this.exercises,
  });

  final int warmupSeconds;
  final int totalSeconds;
  final int totalPhases;
  final int corePhases;
  final List<_GuidedExerciseSummary> exercises;
}

class _GuidedExerciseSummary {
  const _GuidedExerciseSummary({
    required this.name,
    required this.seconds,
    required this.phaseCount,
  });

  final String name;
  final int seconds;
  final int phaseCount;
}

class _GuidedResultCard extends StatelessWidget {
  const _GuidedResultCard({required this.result, required this.formatDuration});

  final GuidedSessionResult result;
  final String Function(int) formatDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = result.completed
        ? 'Guided session finished'
        : 'Guided session interrupted';
    final subtitle = result.completed
        ? '${result.completedExercises}/${result.totalExercises} exercises completed in ${formatDuration(result.elapsedSeconds)}.'
        : 'Stopped at ${formatDuration(result.elapsedSeconds)} with ${result.completedExercises}/${result.totalExercises} exercises completed.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.completed ? Icons.check_circle : Icons.info,
                  color: result.completed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 8),
            Text(
              'Phases: ${result.completedPhases}/${result.totalPhases} completed, ${result.skippedPhases} skipped',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
