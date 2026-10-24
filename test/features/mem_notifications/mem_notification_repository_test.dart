import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem;
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late MemNotificationRepository repository;

  setUp(() {
    final db = AppDatabase.memory();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    Singleton.reset<MemRepository>();
    Singleton.reset<MemNotificationRepository>();
    repository = MemNotificationRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemRepository>();
    Singleton.reset<MemNotificationRepository>();
  });

  test('ship by memId and memIdsIn', () async {
    final mem1 =
        (await MemRepository().receive(Mem(null, 'm1', null, null))).id;
    final mem2 =
        (await MemRepository().receive(Mem(null, 'm2', null, null))).id;
    await MemRepository().receiveRepeatedNotification(
      MemNotification.by(mem1, MemNotificationType.repeat, 300, 'a'),
    );
    await MemRepository().receiveRepeatedNotification(
      MemNotification.by(mem2, MemNotificationType.repeatByNDay, 1, 'b'),
    );

    final byMemId = await repository.ship(memId: mem1);
    expect(byMemId, hasLength(1));
    expect(byMemId.single.memId, mem1);

    final byMemIdsIn = await repository.ship(memIdsIn: [mem2]);
    expect(byMemIdsIn, hasLength(1));
    expect(byMemIdsIn.single.memId, mem2);
  });
}
