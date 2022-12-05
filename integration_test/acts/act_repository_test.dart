import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act_entity.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/errors.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/database/i/types.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/mem_repository.dart';

void main() async {
  final databaseManager = DatabaseManager(onTest: true);

  final defD = DefD('atc_repository_test.db', 1, [
    memTableDefinition,
    actTableDefinition,
  ]);

  late Table memTable;
  late Table actTable;
  await databaseManager.open(defD).then((db) {
    memTable = db.getTable(memTableDefinition.name);
    actTable = db.getTable(actTableDefinition.name);
  });

  tearDownAll(() {
    ActRepository.reset();
    databaseManager.delete(defD.name);
  });

  group('Create instance', () {
    tearDown(() {
      ActRepository.reset();
    });

    test('Singleton', () {
      final first = ActRepository(actTable);

      final second = ActRepository();

      expect(first, same(second));
    });

    test('InitializationError', () {
      expect(() => ActRepository(), throwsA((e) => e is InitializationError));
    });
  });

  group('shipByMemIdIs', () {
    final actRepository = ActRepository(actTable);

    const withNoDataMemId = 404;

    test('without act', () async {
      final memId = await memTable.insert({
        memNameColumnName: 'with no data mem',
        createdAtColumnName: DateTime.now(),
      });
      assert(memId != withNoDataMemId);
      actTable.insert({
        fkDefMemId.name: memId,
        defActStart.name: DateTime.now(),
        defActStartIsAllDay.name: 0,
        createdAtColumnName: DateTime.now(),
      });

      final actual = await actRepository.shipByMemId(withNoDataMemId);

      expect(actual.length, 0);
    });

    test('with act', () async {
      final memId = await memTable.insert({
        memNameColumnName: 'with no data mem',
        createdAtColumnName: DateTime.now(),
      });
      assert(memId != withNoDataMemId);
      final now = DateTime.now();
      actTable.insert({
        fkDefMemId.name: memId,
        defActStart.name: now,
        defActStartIsAllDay.name: 0,
        createdAtColumnName: DateTime.now(),
      });

      final actual = await actRepository.shipByMemId(memId);

      expect(
        actual.toString(),
        [
          Act(memId, DateAndTimePeriod(start: DateAndTime.from(now))),
        ].toString(),
      );
    });
  });
}
