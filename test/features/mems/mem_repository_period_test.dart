import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem;
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late AppDatabase db;
  late MemRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    repository = MemRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemRepository>();
  });

  group('MemRepository period', () {
    test('replace persists notifyAt and round-trips timed period', () async {
      final inserted = await repository.receive(
        Mem(
          null,
          'timed mem',
          null,
          DateAndTimePeriod(
            start: DateAndTime(2024, 6, 1),
            end: DateAndTime(2024, 6, 2),
          ),
        ),
      );

      final timedPeriod = DateAndTimePeriod(
        start: DateAndTime(2024, 6, 1, 14, 30),
        end: DateAndTime(2024, 6, 2),
      );

      await repository.replace(
        MemEntity(
          inserted.id,
          inserted.name,
          inserted.doneAt,
          timedPeriod,
          null,
          inserted.createdAt,
          inserted.updatedAt,
          inserted.archivedAt,
        ),
      );

      final row = await (db.select(db.mems)
            ..where((t) => t.id.equals(inserted.id)))
          .getSingle();

      expect(row.notifyAt, isNotNull);
      expect(row.notifyAt!.hour, 14);
      expect(row.notifyAt!.minute, 30);

      final reloaded = await repository.shipById(inserted.id);

      expect(reloaded.period?.start?.hour, 14);
      expect(reloaded.period?.start?.minute, 30);
      expect(reloaded.period?.start?.isAllDay, isFalse);
    });

    test('replace with all-day start stores null notifyAt (12:00 AM reload)',
        () async {
      final inserted = await repository.receive(
        Mem(
          null,
          'all-day mem',
          null,
          DateAndTimePeriod(
            start: DateAndTime(2024, 6, 1, 10, 0),
            end: DateAndTime(2024, 6, 2),
          ),
        ),
      );

      final allDayPeriod = DateAndTimePeriod(
        start: DateAndTime(2024, 6, 1),
        end: DateAndTime(2024, 6, 2),
      );

      await repository.replace(
        MemEntity(
          inserted.id,
          inserted.name,
          inserted.doneAt,
          allDayPeriod,
          null,
          inserted.createdAt,
          inserted.updatedAt,
          inserted.archivedAt,
        ),
      );

      final row = await (db.select(db.mems)
            ..where((t) => t.id.equals(inserted.id)))
          .getSingle();

      expect(row.notifyAt, isNull);

      final reloaded = await repository.shipById(inserted.id);

      expect(reloaded.period?.start?.isAllDay, isTrue);
      expect(reloaded.period?.start?.hour, 0);
      expect(reloaded.period?.start?.minute, 0);
    });
  });
}
