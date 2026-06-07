import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/notifications/schedule_client.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  group('NotificationClient schedule anchor', () {
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

    Future<int> insertSkippedMemWithRepeatNotification() async {
      final now = DateTime(2024, 10, 12, 12);
      final memId = (await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          ))
          .id;
      final finishStart = now.subtract(const Duration(days: 2));
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: finishStart,
              start: Value(finishStart),
              end: Value(finishStart),
              actKind: const Value('finished'),
            ),
          );
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: now,
              start: Value(now.subtract(const Duration(days: 1))),
              end: Value(now.subtract(const Duration(days: 1))),
              actKind: const Value('skipped'),
            ),
          );
      await MemNotificationRepository().receive(
        MemNotification.by(
          memId,
          MemNotificationType.repeatByNDay,
          1,
          'repeat',
        ),
      );
      return memId;
    }

    test('registerMemNotifications resolves schedule anchor for skipped mem',
        () async {
      final memId = await insertSkippedMemWithRepeatNotification();
      final loaded =
          (await MemRepository().ship(id: memId, loadLatestAct: true)).single;

      expect(loaded.latestAct?.actKind, ActKind.skipped);
      expect(loaded.scheduleAnchorAct?.actKind, ActKind.finished);

      await client.registerMemNotifications(loaded.toDomain());
    });

    test('show repeat consults schedule anchor via shouldNotify', () async {
      final now = DateTime.now();
      final memId = (await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          ))
          .id;
      final activeStart = now.subtract(const Duration(days: 2));
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: activeStart,
              start: Value(activeStart),
            ),
          );
      await MemNotificationRepository().receive(
        MemNotification.by(
          memId,
          MemNotificationType.repeatByNDay,
          7,
          'repeat',
        ),
      );

      await client.show(NotificationType.repeat, memId);
    });
  });
}
