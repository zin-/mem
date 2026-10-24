import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem;
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late MemRepository repository;

  setUp(() {
    final db = AppDatabase.memory();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    Singleton.reset<MemRepository>();
    repository = MemRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemRepository>();
  });

  Future<List<MemNotificationEntity>> storedNotifications(int memId) async =>
      (await repository.shipById(memId)).repeatedNotifications!;

  group('MemRepository repeated notifications', () {
    test('ship attaches each mem notifications and leaves others empty',
        () async {
      final withNotification = await repository.receive(
        Mem(null, 'with', null, null),
      );
      final withoutNotification = await repository.receive(
        Mem(null, 'without', null, null),
      );
      expect(withNotification.repeatedNotifications, isNull);

      await repository.receiveRepeatedNotification(
        MemNotification.by(
          withNotification.id,
          MemNotificationType.repeat,
          300,
          'a',
        ),
      );
      await repository.receiveRepeatedNotification(
        MemNotification.by(
          withNotification.id,
          MemNotificationType.repeatByNDay,
          2,
          'b',
        ),
      );

      final replaced = await repository.replace(
        withNotification.updatedWith(
          update: (mem) => Mem(mem.id, 'renamed', mem.doneAt, mem.period),
        ),
      );
      expect(replaced.repeatedNotifications, isNull);
      expect(replaced.name, 'renamed');

      final all = await repository.ship(loadLatestAct: true);
      final loadedWith =
          all.singleWhere((mem) => mem.id == withNotification.id);
      expect(
        loadedWith.repeatedNotifications!
            .map((notification) => notification.message),
        containsAll(['a', 'b']),
      );
      expect(
        all
            .singleWhere((mem) => mem.id == withoutNotification.id)
            .repeatedNotifications,
        isEmpty,
      );

      final onlyWith = await repository.ship(id: withNotification.id);
      expect(onlyWith.single.repeatedNotifications, hasLength(2));
      expect(
        onlyWith.single.repeatedNotifications!
            .map((notification) => notification.memId),
        everyElement(withNotification.id),
      );
    });

    test('replace updates row and waste filters by memId and type', () async {
      final mem = await repository.receive(Mem(null, 'm', null, null));
      final created = await repository.receiveRepeatedNotification(
        MemNotification.by(mem.id, MemNotificationType.repeat, 60, 'before'),
      );

      final replaced = await repository.replaceRepeatedNotification(
        MemNotificationEntity(
          created.memId,
          created.type,
          created.time,
          'after',
          created.id,
          created.createdAt,
          created.updatedAt,
          created.archivedAt,
        ),
      );

      expect(replaced.message, 'after');
      expect(replaced.id, created.id);
      expect(replaced.updatedAt, isNotNull);

      final deletedByType = await repository.wasteRepeatedNotifications(
        memId: mem.id,
        type: MemNotificationType.repeat,
      );
      expect(deletedByType, hasLength(1));
      expect(await storedNotifications(mem.id), isEmpty);

      await repository.receiveRepeatedNotification(
        MemNotification.by(mem.id, MemNotificationType.repeatByNDay, 2, 'x'),
      );
      final other = await repository.receive(Mem(null, 'other', null, null));
      await repository.receiveRepeatedNotification(
        MemNotification.by(other.id, MemNotificationType.repeat, 30, 'keep'),
      );

      final deletedByMemId = await repository.wasteRepeatedNotifications(
        memId: mem.id,
      );
      expect(deletedByMemId, hasLength(1));
      expect(await storedNotifications(mem.id), isEmpty);
      expect((await storedNotifications(other.id)).single.message, 'keep');
    });
  });

  group('MemService.save notifications', () {
    test('new mem returns inserted notification', () async {
      final (_, savedNotifications, _, _, savedMem) = await MemService().save((
        MemViewData(Mem(null, 'new', null, null)),
        [],
        [
          MemNotificationEntityV1(
            MemNotification.by(
              null,
              MemNotificationType.repeat,
              3600,
              'hello',
            ),
          ),
        ],
        null,
        null,
      ));

      expect(savedNotifications, hasLength(1));
      expect(savedNotifications!.single.memId, savedMem.id);
      expect(savedNotifications.single.message, 'hello');
      expect(savedMem.repeatedNotifications, isNull);

      final stored = await storedNotifications(savedMem.id);
      expect(stored, hasLength(1));
      expect(stored.single.message, 'hello');
    });

    test('saved notification is updated in place', () async {
      final created = await repository.receive(Mem(null, 'saved', null, null));
      final notification = await repository.receiveRepeatedNotification(
        MemNotification.by(
          created.id,
          MemNotificationType.repeat,
          3600,
          'old',
        ),
      );
      final edited =
          SavedMemNotificationEntityV1.fromEntityV2(notification).updatedWith(
        (v) => MemNotification.by(v.memId, v.type, v.time, 'new'),
      );

      final (_, savedNotifications, _, _, savedMem) = await MemService().save((
        MemViewData.fromEntityV2(created),
        [],
        [edited],
        null,
        null,
      ));

      expect(savedNotifications!.single.id, notification.id);
      expect(savedNotifications.single.message, 'new');
      expect(savedMem.repeatedNotifications, isNull);

      final stored = await storedNotifications(created.id);
      expect(stored, hasLength(1));
      expect(stored.single.id, notification.id);
      expect(stored.single.message, 'new');
    });

    test('disabled notification is deleted', () async {
      final created = await repository.receive(Mem(null, 'saved', null, null));
      final repeat = await repository.receiveRepeatedNotification(
        MemNotification.by(created.id, MemNotificationType.repeat, 3600, 'on'),
      );
      final nDay = await repository.receiveRepeatedNotification(
        MemNotification.by(
          created.id,
          MemNotificationType.repeatByNDay,
          2,
          'n',
        ),
      );
      final disabled =
          SavedMemNotificationEntityV1.fromEntityV2(nDay).updatedWith(
        (v) => MemNotification.by(v.memId, v.type, null, v.message),
      );

      final (_, savedNotifications, _, _, _) = await MemService().save((
        MemViewData.fromEntityV2(created),
        [],
        [
          SavedMemNotificationEntityV1.fromEntityV2(repeat),
          disabled,
        ],
        null,
        null,
      ));

      expect(savedNotifications!.map((notification) => notification.type), [
        MemNotificationType.repeat,
      ]);

      final stored = await storedNotifications(created.id);
      expect(stored, hasLength(1));
      expect(stored.single.id, repeat.id);
      expect(stored.single.type, MemNotificationType.repeat);
    });

    test('repeatByDayOfWeek rows are rebuilt', () async {
      final created = await repository.receive(Mem(null, 'saved', null, null));
      final repeat = await repository.receiveRepeatedNotification(
        MemNotification.by(
          created.id,
          MemNotificationType.repeat,
          3600,
          'keep',
        ),
      );
      final monday = await repository.receiveRepeatedNotification(
        MemNotification.by(
          created.id,
          MemNotificationType.repeatByDayOfWeek,
          DateTime.monday,
          'mon',
        ),
      );
      await repository.receiveRepeatedNotification(
        MemNotification.by(
          created.id,
          MemNotificationType.repeatByDayOfWeek,
          DateTime.wednesday,
          'wed',
        ),
      );

      final (_, savedNotifications, _, _, _) = await MemService().save((
        MemViewData.fromEntityV2(created),
        [],
        [
          SavedMemNotificationEntityV1.fromEntityV2(repeat),
          SavedMemNotificationEntityV1.fromEntityV2(monday),
          MemNotificationEntityV1(
            MemNotification.by(
              created.id,
              MemNotificationType.repeatByDayOfWeek,
              DateTime.friday,
              'fri',
            ),
          ),
        ],
        null,
        null,
      ));

      final savedDays = savedNotifications!
          .where((notification) =>
              notification.type == MemNotificationType.repeatByDayOfWeek)
          .toList();
      expect(savedDays.map((notification) => notification.time), [
        DateTime.monday,
        DateTime.friday,
      ]);
      expect(savedDays.map((notification) => notification.id),
          isNot(contains(monday.id)));

      final stored = await storedNotifications(created.id);
      expect(
        stored
            .where((notification) =>
                notification.type == MemNotificationType.repeatByDayOfWeek)
            .map((notification) => notification.time),
        unorderedEquals([DateTime.monday, DateTime.friday]),
      );
      expect(
        stored
            .singleWhere((notification) =>
                notification.type == MemNotificationType.repeat)
            .id,
        repeat.id,
      );
    });

    test('null deletes all notifications of the mem', () async {
      final created = await repository.receive(Mem(null, 'saved', null, null));
      await repository.receiveRepeatedNotification(
        MemNotification.by(created.id, MemNotificationType.repeat, 3600, 'a'),
      );
      await repository.receiveRepeatedNotification(
        MemNotification.by(
          created.id,
          MemNotificationType.repeatByNDay,
          3,
          'b',
        ),
      );
      final other = await repository.receive(Mem(null, 'other', null, null));
      await repository.receiveRepeatedNotification(
        MemNotification.by(other.id, MemNotificationType.repeat, 60, 'keep'),
      );

      final (_, savedNotifications, _, _, _) = await MemService().save((
        MemViewData.fromEntityV2(created),
        [],
        null,
        null,
        null,
      ));

      expect(savedNotifications, isEmpty);
      expect(await storedNotifications(created.id), isEmpty);
      expect((await storedNotifications(other.id)).single.message, 'keep');
    });
  });
}
