import 'package:drift/drift.dart' hide isNull;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mems/list/widget.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time_view.dart';
import 'package:mem/framework/singleton.dart';

class _MidnightPreference extends Preference<TimeOfDay> {
  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 0, minute: 0);
}

void main() {
  group('mem list uses today act count', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Migrator(db).createAll();
      DriftDatabaseAccessor.reset();
      Singleton.override<DriftDatabaseAccessor>(
        DriftDatabaseAccessor.withDatabase(db),
      );
      Singleton.reset<MemRepository>();
    });

    tearDown(() async {
      await db.close();
      DriftDatabaseAccessor.reset();
      Singleton.reset<MemRepository>();
    });

    Future<int> insertMem(String name) async {
      return (await db.into(db.mems).insertReturning(
                MemsCompanion.insert(name: name, createdAt: DateTime.now()),
              ))
          .id;
    }

    Future<void> insertTarget(int memId) async {
      await db.into(db.targets).insert(
            TargetsCompanion.insert(
              type: TargetType.equalTo.name,
              unit: TargetUnit.count.name,
              value: 2,
              period: Period.aDay.name,
              memId: memId,
              createdAt: DateTime.now(),
            ),
          );
    }

    Future<void> insertAct({
      required int memId,
      required DateTime start,
      String actKind = 'finished',
    }) async {
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: start,
              start: Value(start),
              end: Value(start.add(const Duration(minutes: 10))),
              actKind: Value(actKind),
            ),
          );
    }

    Future<void> insertRepeat(int memId) async {
      await MemRepository().receiveRepeatedNotification(
        MemNotification.by(
          memId,
          MemNotificationType.repeat,
          9 * 60 * 60,
          'repeat at 09:00',
        ),
      );
    }

    testWidgets(
        'keeps an unmet daily count on today and a reached one on tomorrow',
        (tester) async {
      final now = DateTime.now();
      final noon = DateTime(now.year, now.month, now.day, 12);
      final yesterdayNoon = noon.subtract(const Duration(days: 1));

      final reachedId = await insertMem('Reached');
      final belowId = await insertMem('Below');
      await insertTarget(reachedId);
      await insertTarget(belowId);
      await insertRepeat(reachedId);
      await insertRepeat(belowId);

      await insertAct(memId: belowId, start: yesterdayNoon);
      await insertAct(
        memId: belowId,
        start: noon.subtract(const Duration(hours: 1)),
        actKind: 'skipped',
      );
      await insertAct(memId: belowId, start: noon);
      await insertAct(memId: reachedId, start: noon);
      await insertAct(
        memId: reachedId,
        start: noon.add(const Duration(hours: 1)),
      );

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceProvider(startOfDayKey)
                .overrideWith(() => _MidnightPreference()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListWidget(scrollController),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DateAndTimeText), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Below')).dy,
        lessThan(tester.getTopLeft(find.text('Reached')).dy),
      );
      expect(belowId, isNot(reachedId));
    });
  });
}
