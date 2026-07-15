import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'app_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final appRepositoryProvider = Provider<AppRepository>(
  (ref) => AppRepository(ref.watch(appDatabaseProvider)),
);
