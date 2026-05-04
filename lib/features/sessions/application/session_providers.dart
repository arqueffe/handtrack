import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_track/features/sessions/data/local/app_database.dart';
import 'package:hand_track/features/sessions/data/local/session_repository.dart';
import 'package:hand_track/features/sessions/domain/session_models.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final repository = SessionRepository(ref.watch(databaseProvider));
  ref.onDispose(repository.dispose);
  return repository;
});

final sessionsProvider = StreamProvider<List<TrainingSession>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchSessions();
});

final homeSnapshotProvider = FutureProvider<HomeSnapshot>((ref) {
  return ref.watch(sessionRepositoryProvider).loadHomeSnapshot();
});
