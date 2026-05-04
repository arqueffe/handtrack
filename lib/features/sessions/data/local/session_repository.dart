import 'dart:async';

import 'package:hand_track/features/sessions/data/local/app_database.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';
import 'package:sqflite/sqflite.dart';

class HomeSnapshot {
  const HomeSnapshot({
    required this.lastHeavyFingerLoad,
    required this.lastPullingPerformance,
    required this.note,
  });

  final String lastHeavyFingerLoad;
  final String lastPullingPerformance;
  final String note;
}

class SessionRepository {
  SessionRepository(this._database);

  final AppDatabase _database;
  final StreamController<List<TrainingSession>> _sessionsController =
      StreamController<List<TrainingSession>>.broadcast();
  bool _seededStream = false;

  Future<void> dispose() async {
    await _sessionsController.close();
  }

  Future<void> saveSession(TrainingSession session) async {
    final db = await _database.database;
    await db.insert('sessions', {
      'id': session.id,
      'session_date': session.sessionDate.toIso8601String(),
      'session_type': session.sessionType.name,
      'fatigue': session.bodyState.fatigue,
      'finger_sensitivity': session.bodyState.fingerSensitivity,
      'finger_load_kg': session.finger?.addedKg,
      'finger_rpe': session.finger?.rpe,
      'pulling_load_kg': session.pulling?.loadKg,
      'pulling_reps': session.pulling?.reps,
      'climbing_grade_score': session.climbing == null
          ? null
          : SessionScoring.gradeToScore(session.climbing!.topGrade),
      'climbing_sends': session.climbing?.sends,
      'climbing_attempts': session.climbing?.attempts,
      'notes': session.notes,
      'payload_json': session.toJsonString(),
      'created_at': session.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _emitSessions();
  }

  Stream<List<TrainingSession>> watchSessions() {
    if (!_seededStream) {
      _seededStream = true;
      unawaited(_emitSessions());
    }
    return _sessionsController.stream;
  }

  Future<List<TrainingSession>> fetchSessions() async {
    final db = await _database.database;
    final rows = await db.query(
      'sessions',
      orderBy: 'session_date DESC, created_at DESC',
    );

    return rows.map(_mapRowToSession).toList(growable: false);
  }

  Future<TrainingSession?> latestSession() async {
    final sessions = await fetchSessions();
    if (sessions.isEmpty) {
      return null;
    }
    return sessions.first;
  }

  Future<TrainingSession?> latestSessionByType(SessionType sessionType) async {
    final db = await _database.database;
    final rows = await db.query(
      'sessions',
      where: 'session_type = ?',
      whereArgs: [sessionType.name],
      orderBy: 'session_date DESC, created_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapRowToSession(rows.first);
  }

  Future<HomeSnapshot> loadHomeSnapshot() async {
    final db = await _database.database;
    final rows = await db.query(
      'sessions',
      orderBy: 'session_date DESC, created_at DESC',
      limit: 20,
    );

    if (rows.isEmpty) {
      return const HomeSnapshot(
        lastHeavyFingerLoad: 'No finger loads logged yet',
        lastPullingPerformance: 'No pull work logged yet',
        note: 'Start your first session to build your baseline.',
      );
    }

    final latest = rows.first;
    Map<String, Object?>? fingerRow;
    Map<String, Object?>? pullingRow;

    for (final row in rows) {
      fingerRow ??= row['finger_load_kg'] != null ? row : null;
      pullingRow ??= row['pulling_load_kg'] != null ? row : null;
      if (fingerRow != null && pullingRow != null) {
        break;
      }
    }

    final finger = fingerRow == null
        ? 'No finger loads logged yet'
        : '${(fingerRow['finger_load_kg'] as num).toStringAsFixed(1)} kg @ RPE ${fingerRow['finger_rpe'] ?? '-'}';

    final pulling = pullingRow == null
        ? 'No pull work logged yet'
        : '${(pullingRow['pulling_load_kg'] as num).toStringAsFixed(1)} kg x ${pullingRow['pulling_reps'] ?? 0}';

    var note = 'Stay consistent. Compare the same stress points.';
    final latestFatigue = (latest['fatigue'] as int?) ?? 0;
    if (latestFatigue >= 8) {
      note = 'Last session: high finger fatigue.';
    } else if (rows.length > 1) {
      final previous = rows[1];
      final latestLoad = (latest['finger_load_kg'] as num?)?.toDouble() ?? 0;
      final previousLoad =
          (previous['finger_load_kg'] as num?)?.toDouble() ?? 0;
      final latestRpe = (latest['finger_rpe'] as int?) ?? 10;
      final previousRpe = (previous['finger_rpe'] as int?) ?? 10;
      final improvedFinger = latestLoad > previousLoad;
      final easierRpe = latestRpe <= previousRpe;
      if (improvedFinger && easierRpe) {
        note = 'Strong finger performance trend.';
      }
    }

    return HomeSnapshot(
      lastHeavyFingerLoad: finger,
      lastPullingPerformance: pulling,
      note: note,
    );
  }

  Future<void> _emitSessions() async {
    final sessions = await fetchSessions();
    if (!_sessionsController.isClosed) {
      _sessionsController.add(sessions);
    }
  }

  TrainingSession _mapRowToSession(Map<String, Object?> row) {
    final payload = row['payload_json'] as String;
    return TrainingSession.fromJsonString(payload);
  }
}
