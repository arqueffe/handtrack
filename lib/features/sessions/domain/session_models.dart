import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum SessionType { strength, endurance, climbing, recovery }

extension SessionTypeLabel on SessionType {
  String get label => switch (this) {
    SessionType.strength => 'Strength',
    SessionType.endurance => 'Endurance',
    SessionType.climbing => 'Climbing',
    SessionType.recovery => 'Recovery',
  };

  static SessionType fromStorage(String value) {
    return SessionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SessionType.strength,
    );
  }
}

@immutable
class FingerLog {
  const FingerLog({
    required this.edgeMm,
    required this.addedKg,
    required this.rpe,
    required this.cleanExecution,
  });

  final int edgeMm;
  final double addedKg;
  final int rpe;
  final bool cleanExecution;

  Map<String, dynamic> toJson() => {
    'edgeMm': edgeMm,
    'addedKg': addedKg,
    'rpe': rpe,
    'cleanExecution': cleanExecution,
  };

  factory FingerLog.fromJson(Map<String, dynamic> json) {
    return FingerLog(
      edgeMm: (json['edgeMm'] as num?)?.toInt() ?? 20,
      addedKg: (json['addedKg'] as num?)?.toDouble() ?? 0,
      rpe: (json['rpe'] as num?)?.toInt() ?? 7,
      cleanExecution: json['cleanExecution'] as bool? ?? true,
    );
  }
}

@immutable
class PullingLog {
  const PullingLog({
    required this.loadKg,
    required this.reps,
    required this.rpe,
  });

  final double loadKg;
  final int reps;
  final int rpe;

  Map<String, dynamic> toJson() => {'loadKg': loadKg, 'reps': reps, 'rpe': rpe};

  factory PullingLog.fromJson(Map<String, dynamic> json) {
    return PullingLog(
      loadKg: (json['loadKg'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      rpe: (json['rpe'] as num?)?.toInt() ?? 7,
    );
  }
}

@immutable
class ClimbingLog {
  const ClimbingLog({
    required this.topGrade,
    required this.sends,
    required this.attempts,
  });

  final String topGrade;
  final int sends;
  final int attempts;

  Map<String, dynamic> toJson() => {
    'topGrade': topGrade,
    'sends': sends,
    'attempts': attempts,
  };

  factory ClimbingLog.fromJson(Map<String, dynamic> json) {
    return ClimbingLog(
      topGrade: json['topGrade'] as String? ?? '',
      sends: (json['sends'] as num?)?.toInt() ?? 0,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class CoreMoment {
  const CoreMoment({required this.name, required this.durationSeconds});

  final String name;
  final int durationSeconds;

  Map<String, dynamic> toJson() => {
    'name': name,
    'durationSeconds': durationSeconds,
  };

  factory CoreMoment.fromJson(Map<String, dynamic> json) {
    final seconds = (json['durationSeconds'] as num?)?.toInt();
    final legacyMinutes = (json['durationMinutes'] as num?)?.toInt();

    return CoreMoment(
      name: json['name'] as String? ?? '',
      durationSeconds: seconds ?? ((legacyMinutes ?? 0) * 60),
    );
  }
}

@immutable
class BodyState {
  const BodyState({required this.fatigue, required this.fingerSensitivity});

  final int fatigue;
  final int fingerSensitivity;

  Map<String, dynamic> toJson() => {
    'fatigue': fatigue,
    'fingerSensitivity': fingerSensitivity,
  };

  factory BodyState.fromJson(Map<String, dynamic> json) {
    return BodyState(
      fatigue: (json['fatigue'] as num?)?.toInt() ?? 5,
      fingerSensitivity: (json['fingerSensitivity'] as num?)?.toInt() ?? 5,
    );
  }
}

enum EnduranceProtocol { repeaters, intermittent }

@immutable
class StrengthSessionDetails {
  const StrengthSessionDetails({
    required this.warmupMinutes,
    required this.maxHangSets,
    required this.maxHangReps,
    required this.hangSeconds,
    required this.restSeconds,
    required this.edgeMm,
    required this.addedKg,
    required this.hangRpe,
    required this.weightedPullupSets,
    required this.weightedPullupReps,
    required this.weightedPullupRestSeconds,
    required this.weightedPullupLoadKg,
    required this.weightedPullupRpe,
    required this.lockOffSets,
    required this.lockOff90Seconds,
    required this.lockOff120Seconds,
    required this.lockOffPerformed,
  });

  final int warmupMinutes;
  final int maxHangSets;
  final int maxHangReps;
  final int hangSeconds;
  final int restSeconds;
  final int edgeMm;
  final double addedKg;
  final int hangRpe;
  final int weightedPullupSets;
  final int weightedPullupReps;
  final int weightedPullupRestSeconds;
  final double weightedPullupLoadKg;
  final int weightedPullupRpe;
  final int lockOffSets;
  final int lockOff90Seconds;
  final int lockOff120Seconds;
  final bool lockOffPerformed;

  Map<String, dynamic> toJson() => {
    'warmupMinutes': warmupMinutes,
    'maxHangSets': maxHangSets,
    'maxHangReps': maxHangReps,
    'hangSeconds': hangSeconds,
    'restSeconds': restSeconds,
    'edgeMm': edgeMm,
    'addedKg': addedKg,
    'hangRpe': hangRpe,
    'weightedPullupSets': weightedPullupSets,
    'weightedPullupReps': weightedPullupReps,
    'weightedPullupRestSeconds': weightedPullupRestSeconds,
    'weightedPullupLoadKg': weightedPullupLoadKg,
    'weightedPullupRpe': weightedPullupRpe,
    'lockOffSets': lockOffSets,
    'lockOff90Seconds': lockOff90Seconds,
    'lockOff120Seconds': lockOff120Seconds,
    'lockOffPerformed': lockOffPerformed,
  };

  factory StrengthSessionDetails.fromJson(Map<String, dynamic> json) {
    return StrengthSessionDetails(
      warmupMinutes: (json['warmupMinutes'] as num?)?.toInt() ?? 10,
      maxHangSets: (json['maxHangSets'] as num?)?.toInt() ?? 3,
      maxHangReps: (json['maxHangReps'] as num?)?.toInt() ?? 3,
      hangSeconds: (json['hangSeconds'] as num?)?.toInt() ?? 7,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 180,
      edgeMm: (json['edgeMm'] as num?)?.toInt() ?? 20,
      addedKg: (json['addedKg'] as num?)?.toDouble() ?? 0,
      hangRpe: (json['hangRpe'] as num?)?.toInt() ?? 7,
      weightedPullupSets: (json['weightedPullupSets'] as num?)?.toInt() ?? 3,
      weightedPullupReps: (json['weightedPullupReps'] as num?)?.toInt() ?? 3,
      weightedPullupRestSeconds:
          (json['weightedPullupRestSeconds'] as num?)?.toInt() ??
          ((json['restSeconds'] as num?)?.toInt() ?? 180),
      weightedPullupLoadKg:
          (json['weightedPullupLoadKg'] as num?)?.toDouble() ?? 0,
      weightedPullupRpe: (json['weightedPullupRpe'] as num?)?.toInt() ?? 7,
      lockOffSets: (json['lockOffSets'] as num?)?.toInt() ?? 0,
      lockOff90Seconds: (json['lockOff90Seconds'] as num?)?.toInt() ?? 0,
      lockOff120Seconds: (json['lockOff120Seconds'] as num?)?.toInt() ?? 0,
      lockOffPerformed: json['lockOffPerformed'] as bool? ?? false,
    );
  }
}

@immutable
class EnduranceSessionDetails {
  const EnduranceSessionDetails({
    required this.warmupMinutes,
    required this.protocol,
    required this.rounds,
    required this.workSeconds,
    required this.restSeconds,
    required this.setRestSeconds,
    required this.sets,
    required this.edgeMm,
    required this.addedKg,
    required this.rpe,
    required this.recoveringWell,
    required this.smallHoldPullupsPerformed,
    required this.smallHoldPullupSets,
    required this.smallHoldPullupReps,
    required this.smallHoldPullupRpe,
  });

  final int warmupMinutes;
  final EnduranceProtocol protocol;
  final int rounds;
  final int workSeconds;
  final int restSeconds;
  final int setRestSeconds;
  final int sets;
  final int edgeMm;
  final double addedKg;
  final int rpe;
  final bool recoveringWell;
  final bool smallHoldPullupsPerformed;
  final int smallHoldPullupSets;
  final int smallHoldPullupReps;
  final int smallHoldPullupRpe;

  Map<String, dynamic> toJson() => {
    'warmupMinutes': warmupMinutes,
    'protocol': protocol.name,
    'rounds': rounds,
    'workSeconds': workSeconds,
    'restSeconds': restSeconds,
    'setRestSeconds': setRestSeconds,
    'sets': sets,
    'edgeMm': edgeMm,
    'addedKg': addedKg,
    'rpe': rpe,
    'recoveringWell': recoveringWell,
    'smallHoldPullupsPerformed': smallHoldPullupsPerformed,
    'smallHoldPullupSets': smallHoldPullupSets,
    'smallHoldPullupReps': smallHoldPullupReps,
    'smallHoldPullupRpe': smallHoldPullupRpe,
  };

  factory EnduranceSessionDetails.fromJson(Map<String, dynamic> json) {
    return EnduranceSessionDetails(
      warmupMinutes: (json['warmupMinutes'] as num?)?.toInt() ?? 10,
      protocol: EnduranceProtocol.values.firstWhere(
        (item) => item.name == (json['protocol'] as String? ?? ''),
        orElse: () => EnduranceProtocol.repeaters,
      ),
      rounds: (json['rounds'] as num?)?.toInt() ?? 6,
      workSeconds: (json['workSeconds'] as num?)?.toInt() ?? 7,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 3,
      setRestSeconds:
          (json['setRestSeconds'] as num?)?.toInt() ??
          ((json['restSeconds'] as num?)?.toInt() ?? 3),
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      edgeMm: (json['edgeMm'] as num?)?.toInt() ?? 20,
      addedKg: (json['addedKg'] as num?)?.toDouble() ?? 0,
      rpe: (json['rpe'] as num?)?.toInt() ?? 7,
      recoveringWell: json['recoveringWell'] as bool? ?? false,
      smallHoldPullupsPerformed:
          json['smallHoldPullupsPerformed'] as bool? ?? false,
      smallHoldPullupSets: (json['smallHoldPullupSets'] as num?)?.toInt() ?? 0,
      smallHoldPullupReps: (json['smallHoldPullupReps'] as num?)?.toInt() ?? 0,
      smallHoldPullupRpe: (json['smallHoldPullupRpe'] as num?)?.toInt() ?? 7,
    );
  }
}

@immutable
class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.sessionDate,
    required this.sessionType,
    required this.bodyState,
    required this.notes,
    required this.createdAt,
    this.finger,
    this.pulling,
    this.climbing,
    this.strengthDetails,
    this.enduranceDetails,
    this.coreMoments = const [],
  });

  factory TrainingSession.create({
    required DateTime sessionDate,
    required SessionType sessionType,
    required BodyState bodyState,
    String notes = '',
    FingerLog? finger,
    PullingLog? pulling,
    ClimbingLog? climbing,
    StrengthSessionDetails? strengthDetails,
    EnduranceSessionDetails? enduranceDetails,
    List<CoreMoment> coreMoments = const [],
  }) {
    return TrainingSession(
      id: const Uuid().v4(),
      sessionDate: sessionDate,
      sessionType: sessionType,
      bodyState: bodyState,
      notes: notes,
      createdAt: DateTime.now(),
      finger: finger,
      pulling: pulling,
      climbing: climbing,
      strengthDetails: strengthDetails,
      enduranceDetails: enduranceDetails,
      coreMoments: coreMoments,
    );
  }

  final String id;
  final DateTime sessionDate;
  final SessionType sessionType;
  final BodyState bodyState;
  final FingerLog? finger;
  final PullingLog? pulling;
  final ClimbingLog? climbing;
  final StrengthSessionDetails? strengthDetails;
  final EnduranceSessionDetails? enduranceDetails;
  final List<CoreMoment> coreMoments;
  final String notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionDate': sessionDate.toIso8601String(),
    'sessionType': sessionType.name,
    'bodyState': bodyState.toJson(),
    'finger': finger?.toJson(),
    'pulling': pulling?.toJson(),
    'climbing': climbing?.toJson(),
    'strengthDetails': strengthDetails?.toJson(),
    'enduranceDetails': enduranceDetails?.toJson(),
    'coreMoments': coreMoments.map((moment) => moment.toJson()).toList(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    final coreRaw = json['coreMoments'] as List<dynamic>? ?? const [];
    return TrainingSession(
      id: json['id'] as String,
      sessionDate: DateTime.parse(json['sessionDate'] as String),
      sessionType: SessionTypeLabel.fromStorage(json['sessionType'] as String),
      bodyState: BodyState.fromJson(json['bodyState'] as Map<String, dynamic>),
      finger: json['finger'] == null
          ? null
          : FingerLog.fromJson(json['finger'] as Map<String, dynamic>),
      pulling: json['pulling'] == null
          ? null
          : PullingLog.fromJson(json['pulling'] as Map<String, dynamic>),
      climbing: json['climbing'] == null
          ? null
          : ClimbingLog.fromJson(json['climbing'] as Map<String, dynamic>),
      strengthDetails: json['strengthDetails'] == null
          ? null
          : StrengthSessionDetails.fromJson(
              json['strengthDetails'] as Map<String, dynamic>,
            ),
      enduranceDetails: json['enduranceDetails'] == null
          ? null
          : EnduranceSessionDetails.fromJson(
              json['enduranceDetails'] as Map<String, dynamic>,
            ),
      coreMoments: coreRaw
          .map((item) => CoreMoment.fromJson(item as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory TrainingSession.fromJsonString(String jsonString) {
    return TrainingSession.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}

class SessionScoring {
  static int? gradeToScore(String gradeRaw) {
    final grade = gradeRaw.trim().toUpperCase();
    if (grade.isEmpty) {
      return null;
    }

    if (grade.startsWith('V')) {
      final number = int.tryParse(grade.substring(1));
      return number;
    }

    final french = RegExp(r'^([4-9])(A|B|C)(\+?)$').firstMatch(grade);
    if (french == null) {
      return null;
    }

    final base = int.parse(french.group(1)!);
    final letter = french.group(2)!;
    final plus = french.group(3) == '+' ? 1 : 0;
    final letterOffset = switch (letter) {
      'A' => 0,
      'B' => 1,
      _ => 2,
    };

    return (base * 10) + (letterOffset * 2) + plus;
  }
}
