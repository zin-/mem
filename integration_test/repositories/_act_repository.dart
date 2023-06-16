import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act_entity.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/errors.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/framework/database/definition.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/mem_entity.dart';

void main() {
  testActRepository();
}

void testActRepository() => group(
      'ActRepository test',
      () {
        final databaseManager = DatabaseManager(onTest: true);

        final defD = DatabaseDefinition('atc_repository_test.db', 1, [
          memTableDefinition,
          actTableDefinition,
        ]);

        late Table memTable;
        late Table actTable;

        setUpAll(() async {
          await databaseManager.open(defD).then((db) {
            memTable = db.getTable(memTableDefinition.name);
            actTable = db.getTable(actTableDefinition.name);
          });
        });

        tearDownAll(() async {
          ActRepository.resetWith(null);
          await databaseManager.delete(defD.name);
        });

        group('Create instance', () {
          setUp(() {
            ActRepository.resetWith(null);
          });
          tearDown(() {
            ActRepository.resetWith(null);
          });

          test('Singleton', () {
            final first = ActRepository(actTable);

            final second = ActRepository();

            expect(first, same(second));
          });

          test('InitializationError', () {
            expect(() => ActRepository(),
                throwsA((e) => e is InitializationError));
          });
        });

        group('shipByMemIdIs', () {
          late ActRepository actRepository;

          setUpAll(() {
            actRepository = ActRepository(actTable);
          });

          const withNoDataMemId = 404;

          test('without act', () async {
            final memId = await memTable.insert({
              defMemName.name: 'with no data mem',
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

          group('with act', () {
            test('only memId', () async {
              final memId = await memTable.insert({
                defMemName.name: 'with mem',
                createdAtColumnName: DateTime.now(),
              });
              assert(memId != withNoDataMemId);
              final now = DateTime.now();
              await actTable.insert({
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

            test(' and period', () async {
              final memId = await memTable.insert({
                defMemName.name: 'with mem',
                createdAtColumnName: DateTime.now(),
              });
              assert(memId != withNoDataMemId);
              final now = DateTime.now();
              await actTable.insert({
                fkDefMemId.name: memId,
                defActStart.name: now,
                defActStartIsAllDay.name: 0,
                createdAtColumnName: DateTime.now(),
              });
              const diff = Duration(days: 1);
              final yesterday = now.subtract(diff);
              await actTable.insert({
                fkDefMemId.name: memId,
                defActStart.name: yesterday,
                defActStartIsAllDay.name: 0,
                createdAtColumnName: DateTime.now(),
              });
              await actTable.insert({
                fkDefMemId.name: memId,
                defActStart.name: yesterday.subtract(diff),
                defActStartIsAllDay.name: 0,
                createdAtColumnName: DateTime.now(),
              });
              final tomorrow = now.add(diff);
              await actTable.insert({
                fkDefMemId.name: memId,
                defActStart.name: tomorrow,
                defActStartIsAllDay.name: 0,
                createdAtColumnName: DateTime.now(),
              });
              await actTable.insert({
                fkDefMemId.name: memId,
                defActStart.name: tomorrow.add(diff),
                defActStartIsAllDay.name: 0,
                createdAtColumnName: DateTime.now(),
              });

              final actual = await actRepository.shipByMemId(
                memId,
                period: DateAndTimePeriod(
                  start: DateAndTime.fromV2(yesterday, timeOfDay: yesterday),
                  end: DateAndTime.fromV2(tomorrow, timeOfDay: tomorrow),
                ),
              );

              expect(
                actual.toString(),
                [
                  Act(memId, DateAndTimePeriod(start: DateAndTime.from(now))),
                  Act(memId,
                      DateAndTimePeriod(start: DateAndTime.from(yesterday))),
                ].toString(),
              );
            });
          });
        });
      },
    );
