import 'package:sqflite/sqlite_api.dart';

// ISSUE #209
class DatabaseAccessor {
  final Database nativeDatabase;

  DatabaseAccessor(this.nativeDatabase);
}
