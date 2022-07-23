import 'package:flutter/foundation.dart';

import 'package:mem/database/database.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';

abstract class DatabaseFactory {
  static Future<Database> open(
    String name,
    int version,
    List<TableDefinition> tables,
  ) async =>
      await (kIsWeb
              ? IndexedDatabase(name, version, tables)
              : SqliteDatabase(name, version, tables))
          .open();
}
