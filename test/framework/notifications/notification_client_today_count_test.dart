import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/notifications/schedule_client.dart';
import 'package:mem/framework/singleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationClient today act count', () {
    late AppDatabase db;
    late NotificationClient client;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      setOnTest(true);
      db = AppDatabase.memory();
      await Migrator(db).createAll();
      DriftDatabaseAccessor.reset();
      Singleton.override<DriftDatabaseAccessor>(
        DriftDatabaseAccessor.withDatabase(db),
      );
      NotificationClient.resetSingleton();
      ScheduleClient.resetSingleton();
      Singleton.reset<MemRepository>();
      Singleton.reset<MemNotificationRepository>();
      client = NotificationClient();
    });

    tearDown(() async {
      await db.close();
      DriftDatabaseAccessor.reset();
      NotificationClient.resetSingleton();
      ScheduleClient.resetSingleton();
      Singleton.reset<MemRepository>();
      Singleton.reset<MemNotificationRepository>();
      setOnTest(false);
    });

    Future<int> insertMem() async {
      return (await db.into(db.mems).insertReturning(
                MemsCompanion.insert(name: 'm', createdAt: DateTime.now()),
              ))
          .id;
    }

    Future<void> insertTarget({
      required int memId,
      required int value,
      int? secondsAfterLastAct,
    }) async {
      await db.into(db.targets).insert(
            TargetsCompanion.insert(
              type: TargetType.equalTo.name,
              unit: TargetUnit.count.name,
              value: value,
              period: Period.aDay.name,
              memId: memId,
              createdAt: DateTime.now(),
              secondsAfterLastAct: Value(secondsAfterLastAct),
            ),
          );
    }

    Future<void> insertAct({
      required int memId,
      required DateTime start,
      required DateTime end,
    }) async {
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: start,
              start: Value(start),
              end: Value(end),
              actKind: const Value('finished'),
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

    test('registerMemNotifications keeps an unmet count on today\'s interval',
        () async {
      final memId = await insertMem();
      final now = DateTime.now();
      final noon = DateTime(now.year, now.month, now.day, 12);
      await insertTarget(
        memId: memId,
        value: 4,
        secondsAfterLastAct: 2 * 60 * 60,
      );
      await insertAct(
        memId: memId,
        start: noon,
        end: noon.add(const Duration(minutes: 10)),
      );
      await insertRepeat(memId);
      final loaded =
          (await MemRepository().ship(id: memId, loadLatestAct: true)).single;

      final registered =
          await client.registerMemNotifications(loaded.toDomain());

      final interval = DateTime(noon.year, noon.month, noon.day, 14, 10);
      final expected = DateTime.now().isAfter(interval)
          ? interval.add(const Duration(days: 1))
          : interval;
      expect(registered, expected);
    });

    test('registerMemNotifications moves on once the count is reached',
        () async {
      final memId = await insertMem();
      final now = DateTime.now();
      final noon = DateTime(now.year, now.month, now.day, 12);
      await insertTarget(
        memId: memId,
        value: 4,
        secondsAfterLastAct: 2 * 60 * 60,
      );
      for (var i = 0; i < 4; i++) {
        final start = noon.add(Duration(hours: i));
        await insertAct(
          memId: memId,
          start: start,
          end: start.add(const Duration(minutes: 10)),
        );
      }
      await insertRepeat(memId);
      final loaded =
          (await MemRepository().ship(id: memId, loadLatestAct: true)).single;

      final registered =
          await client.registerMemNotifications(loaded.toDomain());

      final tomorrow = noon.add(const Duration(days: 1));
      expect(
        registered,
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9),
      );
    });

    test('shouldNotifyRepeat stays true while the daily count is unmet',
        () async {
      final memId = await insertMem();
      final end = DateTime.now().subtract(const Duration(minutes: 30));
      await insertTarget(memId: memId, value: 4);
      await insertAct(
        memId: memId,
        start: end.subtract(const Duration(minutes: 10)),
        end: end,
      );

      expect(await shouldNotifyRepeat(memId), isTrue);
    });

    test('shouldNotifyRepeat suppresses a reached count inside one day',
        () async {
      final memId = await insertMem();
      // 0時直後に実行すると、30分前の実績が前日へ入り当日の回数が未達になる
      final now = DateTime(2026, 6, 15, 15);
      final end = now.subtract(const Duration(minutes: 30));
      await insertTarget(memId: memId, value: 2);
      for (var i = 0; i < 2; i++) {
        final start = end.subtract(Duration(hours: 2 - i));
        await insertAct(memId: memId, start: start, end: end);
      }

      expect(await shouldNotifyRepeat(memId, now: now), isFalse);
    });

    test('shouldNotifyRepeat keeps the one-day suppression for other targets',
        () async {
      final memId = await insertMem();
      final end = DateTime.now().subtract(const Duration(minutes: 30));
      await insertTarget(memId: memId, value: 1);
      await insertAct(
        memId: memId,
        start: end.subtract(const Duration(minutes: 10)),
        end: end,
      );

      expect(await shouldNotifyRepeat(memId), isFalse);
    });

    test('shouldNotifyRepeat is false when today is not a selected weekday',
        () async {
      final memId = await insertMem();
      final now = DateTime(2026, 11, 9, 10);
      final otherWeekday =
          now.weekday == DateTime.monday ? DateTime.tuesday : DateTime.monday;
      await MemRepository().receiveRepeatedNotification(
        MemNotification.by(
          memId,
          MemNotificationType.repeatByDayOfWeek,
          otherWeekday,
          'weekday',
        ),
      );

      expect(await shouldNotifyRepeat(memId, now: now), isFalse);
    });
  });
}
