import 'dart:io';
import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:sqflite/sqlite_api.dart' as sqflite_api;

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is String) {
    return DateTime.parse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

Value<DateTime> _dateTimeValue(Object? value) {
  final dateTime = _parseDateTime(value);
  return dateTime != null ? Value(dateTime) : const Value.absent();
}

Future<void> migrateFromSqflite(AppDatabase database) async {
  final oldDbPath = await DatabaseFactory.buildDatabasePath('mem.db');
  final oldDbFile = File(oldDbPath);

  if (!await oldDbFile.exists()) {
    return;
  }

  await DatabaseTupleRepository.close();

  // ignore: deprecated_member_use_from_same_package
  final oldDb = await DatabaseFactory.nativeFactory.openDatabase(
    oldDbPath,
    options: sqflite_api.OpenDatabaseOptions(
      readOnly: true,
    ),
  );

  try {
    await database.transaction(() async {
      await _migrateMems(database, oldDb);
      await _migrateMemItems(database, oldDb);
      await _migrateActs(database, oldDb);
      await _migrateMemRepeatedNotifications(database, oldDb);
      await _migrateTargets(database, oldDb);
      await _migrateMemRelations(database, oldDb);
    });
  } catch (e, stackTrace) {
    warn('Migration error: $e');
    warn('Stack trace: $stackTrace');
    rethrow;
  } finally {
    await oldDb.close();
  }
}

Future<void> _migrateMems(
    AppDatabase database, sqflite_api.Database oldDb) async {
  final rows = await oldDb.query('mems');
  if (rows.isEmpty) {
    info('Migration: mems table has no data in old database');
    return;
  }

  final companions = rows
      .map((row) => MemsCompanion.insert(
            id: Value(row['id'] as int),
            name: row['name'] as String,
            doneAt: _dateTimeValue(row['doneAt']),
            notifyOn: _dateTimeValue(row['notifyOn']),
            notifyAt: _dateTimeValue(row['notifyAt']),
            endOn: _dateTimeValue(row['endOn']),
            endAt: _dateTimeValue(row['endAt']),
            createdAt: _parseDateTime(row['createdAt'])!,
            updatedAt: _dateTimeValue(row['updatedAt']),
            archivedAt: _dateTimeValue(row['archivedAt']),
          ))
      .toList();

  await database.batch((batch) {
    batch.insertAll(database.mems, companions);
  });
  info('Migration: migrated ${companions.length} rows from mems table');
}

Future<void> _migrateMemItems(
    AppDatabase database, sqflite_api.Database oldDb) async {
  final rows = await oldDb.query('mem_items');
  if (rows.isEmpty) {
    info('Migration: mem_items table has no data in old database');
    return;
  }

  final companions = rows
      .map((row) => MemItemsCompanion.insert(
            id: Value(row['id'] as int),
            type: row['type'] as String,
            value: row['value'] as String,
            memId: row['mems_id'] as int,
            createdAt: _parseDateTime(row['createdAt'])!,
            updatedAt: _dateTimeValue(row['updatedAt']),
            archivedAt: _dateTimeValue(row['archivedAt']),
          ))
      .toList();

  await database.batch((batch) {
    batch.insertAll(database.memItems, companions);
  });
  info('Migration: migrated ${companions.length} rows from mem_items table');
}

Future<void> _migrateActs(
    AppDatabase database, sqflite_api.Database oldDb) async {
  final rows = await oldDb.query('acts');
  if (rows.isEmpty) {
    info('Migration: acts table has no data in old database');
    return;
  }

  final companions = rows
      .map((row) => ActsCompanion.insert(
            id: Value(row['id'] as int),
            start: _dateTimeValue(row['start']),
            startIsAllDay: row['start_is_all_day'] != null
                ? Value((row['start_is_all_day'] as int) != 0)
                : const Value.absent(),
            end: _dateTimeValue(row['end']),
            endIsAllDay: row['end_is_all_day'] != null
                ? Value((row['end_is_all_day'] as int) != 0)
                : const Value.absent(),
            pausedAt: _dateTimeValue(row['paused_at']),
            memId: row['mems_id'] as int,
            createdAt: _parseDateTime(row['createdAt'])!,
            updatedAt: _dateTimeValue(row['updatedAt']),
            archivedAt: _dateTimeValue(row['archivedAt']),
          ))
      .toList();

  await database.batch((batch) {
    batch.insertAll(database.acts, companions);
  });
  info('Migration: migrated ${companions.length} rows from acts table');
}

Future<void> _migrateMemRepeatedNotifications(
    AppDatabase database, sqflite_api.Database oldDb) async {
  final rows = await oldDb.query('mem_repeated_notifications');
  if (rows.isEmpty) {
    info(
        'Migration: mem_repeated_notifications table has no data in old database');
    return;
  }

  final companions = rows
      .map((row) => MemRepeatedNotificationsCompanion.insert(
            id: Value(row['id'] as int),
            timeOfDaySeconds: row['time_of_day_seconds'] as int,
            type: row['type'] as String,
            message: row['message'] as String,
            memId: row['mems_id'] as int,
            createdAt: _parseDateTime(row['createdAt'])!,
            updatedAt: _dateTimeValue(row['updatedAt']),
            archivedAt: _dateTimeValue(row['archivedAt']),
          ))
      .toList();

  await database.batch((batch) {
    batch.insertAll(database.memRepeatedNotifications, companions);
  });
  info(
      'Migration: migrated ${companions.length} rows from mem_repeated_notifications table');
}

Future<void> _migrateTargets(
    AppDatabase database, sqflite_api.Database oldDb) async {
  final rows = await oldDb.query('targets');
  if (rows.isEmpty) {
    info('Migration: targets table has no data in old database');
    return;
  }

  final companions = rows
      .map((row) => TargetsCompanion.insert(
            id: Value(row['id'] as int),
            type: row['type'] as String,
            unit: row['unit'] as String,
            value: row['value'] as int,
            period: row['period'] as String,
            memId: row['mems_id'] as int,
            createdAt: _parseDateTime(row['createdAt'])!,
            updatedAt: _dateTimeValue(row['updatedAt']),
            archivedAt: _dateTimeValue(row['archivedAt']),
          ))
      .toList();

  await database.batch((batch) {
    batch.insertAll(database.targets, companions);
  });
  info('Migration: migrated ${companions.length} rows from targets table');
}

Future<void> _migrateMemRelations(
    AppDatabase database, sqflite_api.Database oldDb) async {
  final rows = await oldDb.query('mem_relations');
  if (rows.isEmpty) {
    info('Migration: mem_relations table has no data in old database');
    return;
  }

  final companions = rows
      .map((row) => MemRelationsCompanion.insert(
            id: Value(row['id'] as int),
            sourceMemId: row['source_mems_id'] as int,
            targetMemId: row['target_mems_id'] as int,
            type: row['type'] as String,
            value: row['value'] != null
                ? Value(row['value'] as int)
                : const Value.absent(),
            createdAt: _parseDateTime(row['createdAt'])!,
            updatedAt: _dateTimeValue(row['updatedAt']),
            archivedAt: _dateTimeValue(row['archivedAt']),
          ))
      .toList();

  await database.batch((batch) {
    batch.insertAll(database.memRelations, companions);
  });
  info(
      'Migration: migrated ${companions.length} rows from mem_relations table');
}
