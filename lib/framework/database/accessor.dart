import 'package:mem/databases/database.dart';
import 'package:mem/framework/singleton.dart';

class DriftDatabaseAccessor {
  final AppDatabase driftDatabase;

  DriftDatabaseAccessor._(this.driftDatabase);

  factory DriftDatabaseAccessor.withDatabase(AppDatabase database) =>
      DriftDatabaseAccessor._(database);

  factory DriftDatabaseAccessor() =>
      Singleton.of(() => DriftDatabaseAccessor._(AppDatabase()));

  Future<void> close() async {
    await driftDatabase.close();
  }

  static void reset() {
    Singleton.reset<DriftDatabaseAccessor>();
  }
}
