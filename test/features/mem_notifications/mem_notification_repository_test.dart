import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late AppDatabase db;
  late MemNotificationRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    repository = MemNotificationRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemNotificationRepository>();
  });

  Future<int> createMem(String name) async {
    final row = await db.into(db.mems).insertReturning(
          MemsCompanion.insert(
            name: name,
            createdAt: DateTime(2024, 1, 1),
          ),
        );
    return row.id;
  }

  test('receive and ship by memId and memIdsIn', () async {
    final mem1 = await createMem('m1');
    final mem2 = await createMem('m2');
    await repository.receive(
      MemNotification.by(mem1, MemNotificationType.repeat, 300, 'a'),
    );
    await repository.receive(
      MemNotification.by(mem2, MemNotificationType.repeatByNDay, 1, 'b'),
    );

    final byMemId = await repository.ship(memId: mem1);
    expect(byMemId, hasLength(1));
    expect(byMemId.single.memId, mem1);

    final byMemIdsIn = await repository.ship(memIdsIn: [mem2]);
    expect(byMemIdsIn, hasLength(1));
    expect(byMemIdsIn.single.memId, mem2);
  });

  test('replace updates row and waste filters by memId/type', () async {
    final memId = await createMem('m');
    final created = await repository.receive(
      MemNotification.by(memId, MemNotificationType.repeat, 60, 'before'),
    );
    final domain = created.toDomain();
    final replaced = await repository.replace(
      MemNotificationEntity(
        domain.memId,
        domain.type,
        domain.time,
        'after',
        created.id,
        created.createdAt,
        created.updatedAt,
        created.archivedAt,
      ),
    );

    expect(replaced.message, 'after');

    final deletedByType = await repository.waste(
      memId: memId,
      type: MemNotificationType.repeat,
    );
    expect(deletedByType, hasLength(1));

    await repository.receive(
      MemNotification.by(memId, MemNotificationType.repeatByNDay, 2, 'x'),
    );
    final deletedByMemId = await repository.waste(memId: memId);
    expect(deletedByMemId, hasLength(1));
  });
}
