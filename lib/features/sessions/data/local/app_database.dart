import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static bool _ffiInitialized = false;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final factory = _resolveFactory();
    final basePath = await factory.getDatabasesPath();
    final dbPath = p.join(basePath, 'hand_track.db');

    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE sessions (
              id TEXT PRIMARY KEY,
              session_date TEXT NOT NULL,
              session_type TEXT NOT NULL,
              fatigue INTEGER NOT NULL,
              finger_sensitivity INTEGER NOT NULL,
              finger_load_kg REAL,
              finger_rpe INTEGER,
              pulling_load_kg REAL,
              pulling_reps INTEGER,
              climbing_grade_score INTEGER,
              climbing_sends INTEGER,
              climbing_attempts INTEGER,
              notes TEXT NOT NULL DEFAULT '',
              payload_json TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  DatabaseFactory _resolveFactory() {
    if (Platform.isWindows || Platform.isLinux) {
      if (!_ffiInitialized) {
        sqfliteFfiInit();
        _ffiInitialized = true;
      }
      return databaseFactoryFfi;
    }

    return databaseFactory;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
