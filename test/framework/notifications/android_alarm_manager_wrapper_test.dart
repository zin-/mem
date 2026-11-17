import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/notifications/android_alarm_manager_wrapper.dart';

void _alarmCallback(int id, Map<String, dynamic> params) {}

void main() {
  const channel = MethodChannel(
    'dev.fluttercommunity.plus/android_alarm_manager',
    JSONMethodCodec(),
  );
  // CallbackHandle の生値。テストのコールバックは isolate に登録できない
  const rawHandle = 4;
  // AlarmManager の id。32bit に収まる
  const id = 1;
  final startAt = DateTime(2026, 11, 17, 9, 30);
  const params = <String, dynamic>{'memId': 1};
  // true だけだと、引数を渡していない実装と区別できない
  const exact = true;
  const allowWhileIdle = false;
  const wakeup = true;
  const rescheduleOnReboot = false;
  // wrapper は alarmClock を渡さない。プラグインの既定
  const alarmClock = false;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    AndroidAlarmManager.setTestOverrides(
      getCallbackHandle: (_) => CallbackHandle.fromRawHandle(rawHandle),
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    AndroidAlarmManager.setTestOverrides(
      getCallbackHandle: PluginUtilities.getCallbackHandle,
    );
  });

  List<MethodCall> recordCalls({required bool started}) {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'AlarmService.start') {
        return started;
      }
      return true;
    });
    return calls;
  }

  Future<void> oneShot(AndroidAlarmManagerWrapper wrapper) => wrapper.oneShotAt(
        id: id,
        startAt: startAt,
        params: params,
        callback: _alarmCallback,
        exact: exact,
        allowWhileIdle: allowWhileIdle,
        wakeup: wakeup,
        rescheduleOnReboot: rescheduleOnReboot,
      );

  test('oneShotAt forwards the alarm after initialize', () async {
    final calls = recordCalls(started: true);
    final wrapper = AndroidAlarmManagerWrapper();

    await oneShot(wrapper);
    await oneShot(wrapper);

    expect(calls.map((call) => call.method), [
      'AlarmService.start',
      'Alarm.oneShotAt',
      'Alarm.oneShotAt',
    ]);
    expect(calls[1].arguments, [
      id,
      alarmClock,
      allowWhileIdle,
      exact,
      wakeup,
      startAt.millisecondsSinceEpoch,
      rescheduleOnReboot,
      rawHandle,
      params,
    ]);
    expect(calls[2].arguments, calls[1].arguments);
  });

  test('oneShotAt does not schedule when initialize fails', () async {
    final calls = recordCalls(started: false);

    await oneShot(AndroidAlarmManagerWrapper());

    expect(calls.map((call) => call.method), ['AlarmService.start']);
  });

  test('cancel removes that id after initialize', () async {
    final calls = recordCalls(started: true);

    await AndroidAlarmManagerWrapper().cancel(id);

    expect(calls.map((call) => call.method), [
      'AlarmService.start',
      'Alarm.cancel',
    ]);
    expect(calls[1].arguments, [id]);
  });

  test('cancel does nothing when initialize fails', () async {
    final calls = recordCalls(started: false);

    await AndroidAlarmManagerWrapper().cancel(id);

    expect(calls.map((call) => call.method), ['AlarmService.start']);
  });
}
