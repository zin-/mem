import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/notifications/android_alarm_manager_wrapper.dart';
import 'package:mem/framework/notifications/mem_notifications.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/notifications/notification_ids.dart';
import 'package:mem/framework/notifications/schedule.dart';
import 'package:mem/framework/notifications/schedule_client.dart';
import 'package:mem/framework/permissions/permission.dart';
import 'package:mem/values/constants.dart';

void main() {
  // mem 1 の開始通知。AlarmManager の id は 32bit に収まる
  final id = memStartNotificationId(1);
  // 同じ mem の終了通知。置き換えや取り消しが他の id を消さないことを見る
  final otherId = memEndNotificationId(1);
  // 表示時刻。one-shot の発火時刻と一致する
  final startAt = DateTime(2026, 11, 17, 9, 30);
  // 同じ id の再登録で置き換わる、より後の表示時刻
  final replacedAt = DateTime(2026, 11, 18, 9, 30);
  const params = <String, dynamic>{
    memIdKey: 1,
    notificationTypeKey: 'repeat',
  };
  // 1日。繰り返しの周期だが、OS には渡さない
  const period = Duration(days: 1);

  late _RecordingAlarmScheduler scheduler;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async => true);
    ScheduleClient.resetSingleton();
    scheduler = _RecordingAlarmScheduler();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
    ScheduleClient.resetSingleton();
  });

  ScheduleClient client() => ScheduleClient(scheduler: scheduler);

  void expectExactOneShot(_OneShot alarm, DateTime at) {
    expect(alarm.startAt, at);
    expect(alarm.params, params);
    expect(alarm.exact, isTrue);
    expect(alarm.allowWhileIdle, isTrue);
    expect(alarm.wakeup, isTrue);
    expect(alarm.rescheduleOnReboot, isTrue);
    expect(alarm.callback, same(scheduleCallback));
  }

  test('TimedSchedule registers one exact one-shot at startAt', () async {
    await client().receive(TimedSchedule(id, startAt, params));

    expect(scheduler.alarms, hasLength(1));
    expectExactOneShot(scheduler.alarms[id]!, startAt);
  });

  test('PeriodicSchedule registers one exact one-shot at startAt', () async {
    await client().receive(
      PeriodicSchedule(id, startAt, period, params),
    );

    expect(scheduler.alarms, hasLength(1));
    expectExactOneShot(scheduler.alarms[id]!, startAt);
  });

  test('receiving the same id replaces the one-shot', () async {
    await client().receive(TimedSchedule(id, startAt, params));
    await client().receive(TimedSchedule(otherId, startAt, params));
    await client().receive(PeriodicSchedule(id, replacedAt, period, params));

    expect(scheduler.alarms, hasLength(2));
    expectExactOneShot(scheduler.alarms[id]!, replacedAt);
    expectExactOneShot(scheduler.alarms[otherId]!, startAt);
  });

  test('CancelSchedule cancels that id', () async {
    await client().receive(TimedSchedule(id, startAt, params));
    await client().receive(TimedSchedule(otherId, startAt, params));

    await client().receive(CancelSchedule(id));

    expect(scheduler.alarms.keys, [otherId]);
  });

  test('discard cancels that id', () async {
    await client().receive(PeriodicSchedule(id, startAt, period, params));

    await client().discard(id);

    expect(scheduler.alarms, isEmpty);
  });

  test('does not register a one-shot when exact alarm permission is denied',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });
    final requested = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      final names =
          ((call.arguments as Map)[permissionNames] as List).cast<String>();
      requested.addAll(names);
      return !names.contains(Permission.scheduleExactAlarm.name);
    });

    await client().receive(TimedSchedule(id, startAt, params));

    expect(scheduler.alarms, isEmpty);
    expect(requested, contains(Permission.scheduleExactAlarm.name));
  });
}

class _OneShot {
  final int id;
  final DateTime startAt;
  final Map<String, dynamic> params;
  final bool exact;
  final bool allowWhileIdle;
  final bool wakeup;
  final bool rescheduleOnReboot;
  final Function callback;

  _OneShot({
    required this.id,
    required this.startAt,
    required this.params,
    required this.exact,
    required this.allowWhileIdle,
    required this.wakeup,
    required this.rescheduleOnReboot,
    required this.callback,
  });
}

class _RecordingAlarmScheduler implements AlarmScheduler {
  final alarms = <int, _OneShot>{};

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
    alarms[id] = _OneShot(
      id: id,
      startAt: startAt,
      params: params,
      exact: exact,
      allowWhileIdle: allowWhileIdle,
      wakeup: wakeup,
      rescheduleOnReboot: rescheduleOnReboot,
      callback: callback,
    );
  }

  @override
  Future<void> cancel(int id) async {
    alarms.remove(id);
  }
}
