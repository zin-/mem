import 'package:sqflite/sqlite_api.dart';

// ISSUE #209
class DatabaseAccessor {
  @Deprecated("Use only for developing.")
  final Database nativeDatabase;

  DatabaseAccessor(this.nativeDatabase);
}
