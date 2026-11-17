import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/notifications/android_alarm_manager_wrapper.dart';
import 'package:mem/framework/notifications/mem_notifications.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/notifications/notification_ids.dart';
import 'package:mem/framework/notifications/schedule_client.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/values/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 秒。09:30。発火時刻と同時刻だと MemNotifyAt.repeat は同じ時刻を返す
  const repeatAtSeconds = 9 * 60 * 60 + 30 * 60;
  // 実行時刻より十分先。DateTime.now() ではこの翌日にならない
  final firedAt = DateTime(2099, 1, 1, 9, 30);
  final nextAt = DateTime(2099, 1, 2, 9, 30);

  late AppDatabase db;
  late _RecordingAlarmScheduler scheduler;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async => true);
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
    scheduler = _RecordingAlarmScheduler();
    ScheduleClient(scheduler: scheduler);
    NotificationClient();
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
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
              MemsCompanion.insert(name: 'm', createdAt: firedAt),
            ))
        .id;
  }

  Future<void> insertRepeat(int memId) async {
    await MemRepository().receiveRepeatedNotification(
      MemNotification.by(
        memId,
        MemNotificationType.repeat,
        repeatAtSeconds,
        'repeat at 09:30',
      ),
    );
  }

  Future<void> fireRepeat(int memId) async {
    await scheduleCallback(
      memRepeatedNotificationId(memId),
      {
        memIdKey: memId,
        notificationTypeKey: NotificationType.repeat.name,
      },
      firedAt: firedAt,
    );
    // receive は完了を待たずに返る
    await pumpEventQueue();
  }

  test('repeat callback registers the next startAt after the fire time',
      () async {
    final memId = await insertMem();
    await insertRepeat(memId);

    await fireRepeat(memId);

    expect(scheduler.alarms[memRepeatedNotificationId(memId)], nextAt);
  });

  test('repeat callback registers the next startAt when display is suppressed',
      () async {
    final memId = await insertMem();
    await insertRepeat(memId);
    // 1時間前の完了。1日以内なので、この発火は表示しない
    final end = DateTime.now().subtract(const Duration(hours: 1));
    await db.into(db.acts).insert(
          ActsCompanion.insert(
            memId: memId,
            createdAt: end,
            start: Value(end.subtract(const Duration(minutes: 10))),
            end: Value(end),
            actKind: const Value('finished'),
          ),
        );

    await fireRepeat(memId);

    expect(scheduler.alarms[memRepeatedNotificationId(memId)], nextAt);
  });
}

class _RecordingAlarmScheduler implements AlarmScheduler {
  final alarms = <int, DateTime>{};

  @override
  Future<void> oneShotAt({
    required int id,
    required DateTime startAt,
    required Map<String, dynamic> params,
    required Function callback,
    required bool exact,
    required bool allowWhileIdle,
    required bool wakeup,
    required bool rescheduleOnReboot,
  }) async {
    alarms[id] = startAt;
  }

  @override
  Future<void> cancel(int id) async {
    alarms.remove(id);
  }
}
