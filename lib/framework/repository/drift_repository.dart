import 'package:mem/databases/database.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/repository.dart';

abstract class DriftRepository extends Repository {
  AppDatabase get driftDb => DriftDatabaseAccessor().driftDatabase;

  DriftDatabaseAccessor get driftAccessor => DriftDatabaseAccessor();

  static Future<void> close() async {
    await DriftDatabaseAccessor().close();
    DriftDatabaseAccessor.reset();
  }
}
