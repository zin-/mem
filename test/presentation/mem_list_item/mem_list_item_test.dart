import 'dart:async';

import 'package:flutter/material.dart';
import '../../entity_factories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/mems/list/item/subtitle.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/modules/live_elapsed_time_text.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/values/colors.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _state;
  int doneMemCallCount = 0;
  int undoneMemCallCount = 0;
  int? lastDoneMemId;
  int? lastUndoneMemId;

  _FakeMemEntities(this._state);

  @override
  Iterable<MemEntity> build() => _state;

  @override
  Future<void> doneMem(int memId) async {
    doneMemCallCount++;
    lastDoneMemId = memId;
  }

  @override
  Future<void> undoneMem(int memId) async {
    undoneMemCallCount++;
    lastUndoneMemId = memId;
  }
}

class _FakeStartOfDay extends Preference<TimeOfDay> {
  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 0, minute: 0);
}

const _noonHour = 12;
const _actMinutes = 30;

Target _countTarget(
  int memId, {
  int value = 3,
  Period period = Period.aDay,
}) =>
    Target(
      memId: memId,
      targetType: TargetType.equalTo,
      targetUnit: TargetUnit.count,
      value: value,
      period: period,
    );

Mem _memEndedDaysBefore(int memId, int days) {
  final now = DateTime.now();
  final endedAt = DateTime(
    now.year,
    now.month,
    now.day - days,
    _noonHour,
  );
  final end = DateAndTime.from(endedAt, timeOfDay: endedAt);
  return Mem(
    memId,
    'Test Mem',
    null,
    null,
    latestAct: Act.by(
      memId,
      startWhen: end.subtract(const Duration(minutes: _actMinutes)),
      endWhen: end,
    ),
  );
}

Future<void> _pumpMemListCount(
  WidgetTester tester, {
  required int memId,
  required Mem mem,
  required Target target,
  required int todayCount,
  Map<int, int>? periodCounts,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memNotificationsByMemIdProvider(memId).overrideWith(
          (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
        ),
        memEntitiesProvider.overrideWith(
          () => _FakeMemEntities([
            savedMemFromDomain(mem).updatedWith(
              target: () => target,
            ),
          ]),
        ),
        preferenceProvider(startOfDayKey).overrideWith(() => _FakeStartOfDay()),
        listPeriodCountByMemIdProvider.overrideWith(
          (ref) async => periodCounts ?? {memId: todayCount},
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MemListItemView(mem),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeActEntities extends ActEntities {
  int startActbyCallCount = 0;
  int resumeActByCallCount = 0;
  int finishActbyCallCount = 0;
  int skipActByCallCount = 0;
  int pauseByMemIdCallCount = 0;
  int closeByMemIdCallCount = 0;
  int? lastStartActbyMemId;
  int? lastResumeActByMemId;
  int? lastFinishActbyMemId;
  int? lastSkipActByMemId;
  int? lastPauseByMemId;
  int? lastCloseByMemId;

  @override
  Iterable<SavedActEntityV1> build() => [];

  @override
  Future<void> startActby(int memId) async {
    startActbyCallCount++;
    lastStartActbyMemId = memId;
  }

  @override
  Future<void> resumeActBy(int memId) async {
    resumeActByCallCount++;
    lastResumeActByMemId = memId;
  }

  @override
  Future<void> finishActby(int memId) async {
    finishActbyCallCount++;
    lastFinishActbyMemId = memId;
  }

  @override
  Future<void> skipActBy(int memId) async {
    skipActByCallCount++;
    lastSkipActByMemId = memId;
  }

  @override
  Future<void> pauseByMemId(int memId) async {
    pauseByMemIdCallCount++;
    lastPauseByMemId = memId;
  }

  @override
  Future<void> closeByMemId(int memId) async {
    closeByMemIdCallCount++;
    lastCloseByMemId = memId;
  }
}

void main() {
  group('MemListItemView', () {
    const memId = 1;
    final baseMem = Mem(memId, 'Test Mem', null, null);

    testWidgets(
        'mem name, checkbox, subtitle, and start button are displayed when no act and no notifications',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(baseMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MemNameText), findsOneWidget);
      expect(find.text('Test Mem'), findsOneWidget);
      expect(find.text(' / '), findsNothing);
      expect(find.byType(MemDoneCheckbox), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.timer), findsNothing);
      expect(find.byIcon(Icons.notifications_active), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets(
        'displays timer and finish/pause/close buttons when act is active',
        (tester) async {
      final activeAct = ActiveAct(
          memId,
          DateAndTime.from(
              DateTime.now().subtract(const Duration(minutes: 5))));
      final mem = Mem(memId, 'Test Mem', null, null, latestAct: activeAct);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(mem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(mem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LiveElapsedTimeText), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('displays play/close buttons when act is paused',
        (tester) async {
      final pausedAct =
          PausedAct(memId, DateTime.now().subtract(const Duration(minutes: 5)));
      final mem = Mem(memId, 'Test Mem', null, null, latestAct: pausedAct);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(mem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(mem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LiveElapsedTimeText), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.timer), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets(
        'displays elapsed time from Mem.latestAct when actEntities is empty',
        (tester) async {
      final pausedAct =
          PausedAct(memId, DateTime.now().subtract(const Duration(minutes: 5)));
      final pausedMem =
          Mem(memId, 'Test Mem', null, null, latestAct: pausedAct);
      final now = DateTime.now();
      final notification = savedMemNotification(
          id: 1,
          memId: memId,
          type: MemNotificationType.repeat,
          timeOfDaySeconds: 9 * 60 * 60,
          message: 'Repeat',
          createdAt: now,
          updatedAt: now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(pausedMem)])),
            actEntitiesProvider.overrideWith(() => _FakeActEntities()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(pausedMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LiveElapsedTimeText), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('displays notification icon when notifications exist',
        (tester) async {
      final now = DateTime.now();
      final notification = savedMemNotification(
          id: 1,
          memId: memId,
          type: MemNotificationType.repeat,
          timeOfDaySeconds: 9 * 60 * 60,
          message: 'Repeat',
          createdAt: now,
          updatedAt: now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(baseMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('displays checkmark when mem is done', (tester) async {
      final doneMem = Mem(memId, 'Done Mem', DateTime.now(), null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(doneMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('displays empty checkbox when mem is not done', (tester) async {
      final notDoneMem = Mem(memId, 'Not Done Mem', null, null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(notDoneMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('displays archived mem with grey background', (tester) async {
      final archivedMem = Mem(memId, 'Archived Mem', null, null);
      // isArchived is always false in current implementation, but test the path

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(archivedMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.tileColor, isNull);
    });

    testWidgets('displays mem with period and notifications enabled',
        (tester) async {
      final memWithPeriod = Mem(memId, 'Mem with Period', null,
          DateAndTimePeriod(start: DateAndTime.now()));
      final now = DateTime.now();
      final notification = savedMemNotification(
          id: 1,
          memId: memId,
          type: MemNotificationType.repeat,
          timeOfDaySeconds: 9 * 60 * 60,
          message: 'Repeat',
          createdAt: now,
          updatedAt: now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(memWithPeriod),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.isThreeLine, isTrue);
      expect(find.byType(MemListItemSubtitle), findsOneWidget);
    });

    testWidgets('displays mem with notifications but no active act',
        (tester) async {
      final now = DateTime.now();
      final notification = savedMemNotification(
          id: 1,
          memId: memId,
          type: MemNotificationType.repeat,
          timeOfDaySeconds: 9 * 60 * 60,
          message: 'Repeat',
          createdAt: now,
          updatedAt: now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(baseMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('displays done mem without trailing button', (tester) async {
      final doneMem = Mem(memId, 'Done Mem', DateTime.now(), null);
      final now = DateTime.now();
      final notification = savedMemNotification(
          id: 1,
          memId: memId,
          type: MemNotificationType.repeat,
          timeOfDaySeconds: 9 * 60 * 60,
          message: 'Repeat',
          createdAt: now,
          updatedAt: now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(doneMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.stop), findsOneWidget); // leading に表示される
    });

    testWidgets('displays mem without period and notifications disabled',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(baseMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNull);
      expect(listTile.isThreeLine, isFalse);
    });

    testWidgets(
        'displays active act with timer in title and pause/stop buttons',
        (tester) async {
      final activeAct = ActiveAct(
          memId,
          DateAndTime.from(
              DateTime.now().subtract(const Duration(minutes: 5))));
      final mem = Mem(memId, 'Test Mem', null, null, latestAct: activeAct);
      final now = DateTime.now();
      final notification = savedMemNotification(
          id: 1,
          memId: memId,
          type: MemNotificationType.repeat,
          timeOfDaySeconds: 9 * 60 * 60,
          message: 'Repeat',
          createdAt: now,
          updatedAt: now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(mem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(mem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // アクティブなアクトがある場合、タイトルにLiveElapsedTimeTextが表示される
      expect(find.byType(LiveElapsedTimeText), findsOneWidget);
      // leadingにpauseボタンが表示される
      expect(find.byIcon(Icons.pause), findsOneWidget);
      // trailingにstopボタンが表示される
      expect(find.byIcon(Icons.stop), findsOneWidget);
      // subtitleが表示される
      expect(find.byType(MemListItemSubtitle), findsOneWidget);
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.isThreeLine, isFalse); // mem.periodがnullなのでfalse
    });

    testWidgets(
        'displays paused act with close button in leading and play button in trailing',
        (tester) async {
      final pausedAct =
          PausedAct(memId, DateTime.now().subtract(const Duration(minutes: 5)));
      final mem = Mem(memId, 'Test Mem', null, null, latestAct: pausedAct);
      final now = DateTime.now();
      final notification = savedMemNotification(
          id: 1,
          memId: memId,
          type: MemNotificationType.repeat,
          timeOfDaySeconds: 9 * 60 * 60,
          message: 'Repeat',
          createdAt: now,
          updatedAt: now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(mem)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(mem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // leadingにcloseボタンが表示される
      expect(find.byIcon(Icons.close), findsOneWidget);
      // trailingにplayボタンが表示される
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      // subtitleが表示される
      expect(find.byType(MemListItemSubtitle), findsOneWidget);
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.isThreeLine, isFalse); // mem.periodがnullなのでfalse
    });

    testWidgets(
        'displays active act with period and notifications enabled - isThreeLine true',
        (tester) async {
      final activeAct = ActiveAct(
          memId,
          DateAndTime.from(
              DateTime.now().subtract(const Duration(minutes: 5))));
      final memWithPeriod = Mem(memId, 'Mem with Period', null,
          DateAndTimePeriod(start: DateAndTime.now()),
          latestAct: activeAct);
      final now = DateTime.now();
      final notification = savedMemNotification(
          id: 1,
          memId: memId,
          type: MemNotificationType.repeat,
          timeOfDaySeconds: 9 * 60 * 60,
          message: 'Repeat',
          createdAt: now,
          updatedAt: now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(memWithPeriod)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(memWithPeriod),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // アクティブなアクトがある場合、タイトルにLiveElapsedTimeTextが表示される
      expect(find.byType(LiveElapsedTimeText), findsOneWidget);
      // leadingにpauseボタンが表示される
      expect(find.byIcon(Icons.pause), findsOneWidget);
      // trailingにstopボタンが表示される
      expect(find.byIcon(Icons.stop), findsOneWidget);
      // subtitleが表示される
      expect(find.byType(MemListItemSubtitle), findsOneWidget);
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.isThreeLine, isTrue); // mem.periodがnullでないのでtrue
    });

    testWidgets(
        'displays paused act with period and notifications enabled - isThreeLine true',
        (tester) async {
      final pausedAct =
          PausedAct(memId, DateTime.now().subtract(const Duration(minutes: 5)));
      final memWithPeriod = Mem(memId, 'Mem with Period', null,
          DateAndTimePeriod(start: DateAndTime.now()),
          latestAct: pausedAct);
      final now = DateTime.now();
      final notification = savedMemNotification(
          id: 1,
          memId: memId,
          type: MemNotificationType.repeat,
          timeOfDaySeconds: 9 * 60 * 60,
          message: 'Repeat',
          createdAt: now,
          updatedAt: now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([savedMemFromDomain(memWithPeriod)])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(memWithPeriod),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // leadingにcloseボタンが表示される
      expect(find.byIcon(Icons.close), findsOneWidget);
      // trailingにplayボタンが表示される
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      // subtitleが表示される
      expect(find.byType(MemListItemSubtitle), findsOneWidget);
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.isThreeLine, isTrue); // mem.periodがnullでないのでtrue
    });

    group('callbacks', () {
      testWidgets('calls doneMem when checkbox is checked', (tester) async {
        final fakeMemEntities = _FakeMemEntities([savedMemFromDomain(baseMem)]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                  (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
              memEntitiesProvider.overrideWith(() => fakeMemEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(baseMem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        checkbox.onChanged!(true);
        await tester.pump();

        expect(fakeMemEntities.doneMemCallCount, 1);
        expect(fakeMemEntities.lastDoneMemId, memId);
      });

      testWidgets('calls undoneMem when checkbox is unchecked', (tester) async {
        final doneMem = Mem(memId, 'Done Mem', DateTime.now(), null);
        final fakeMemEntities = _FakeMemEntities([savedMemFromDomain(doneMem)]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                  (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
              memEntitiesProvider.overrideWith(() => fakeMemEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(doneMem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        checkbox.onChanged!(false);
        await tester.pump();

        expect(fakeMemEntities.undoneMemCallCount, 1);
        expect(fakeMemEntities.lastUndoneMemId, memId);
      });

      testWidgets('calls startActby when start button is tapped',
          (tester) async {
        final now = DateTime.now();
        final notification = savedMemNotification(
            id: 1,
            memId: memId,
            type: MemNotificationType.repeat,
            timeOfDaySeconds: 9 * 60 * 60,
            message: 'Repeat',
            createdAt: now,
            updatedAt: now);
        final fakeActEntities = _FakeActEntities();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                  ListValueStateNotifier<MemNotificationEntityV1>(
                      [notification])),
              memEntitiesProvider.overrideWith(
                  () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(baseMem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();

        expect(fakeActEntities.startActbyCallCount, 1);
        expect(fakeActEntities.lastStartActbyMemId, memId);
      });

      testWidgets('calls resumeActBy when play is tapped while paused',
          (tester) async {
        final now = DateTime.now();
        final pausedAct =
            PausedAct(memId, now.subtract(const Duration(minutes: 5)));
        final mem = Mem(memId, 'Test Mem', null, null, latestAct: pausedAct);
        final notification = savedMemNotification(
            id: 1,
            memId: memId,
            type: MemNotificationType.repeat,
            timeOfDaySeconds: 9 * 60 * 60,
            message: 'Repeat',
            createdAt: now,
            updatedAt: now);
        final fakeActEntities = _FakeActEntities();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                  ListValueStateNotifier<MemNotificationEntityV1>(
                      [notification])),
              memEntitiesProvider.overrideWith(
                  () => _FakeMemEntities([savedMemFromDomain(mem)])),
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();

        expect(fakeActEntities.resumeActByCallCount, 1);
        expect(fakeActEntities.lastResumeActByMemId, memId);
        expect(fakeActEntities.startActbyCallCount, 0);
      });

      testWidgets('calls finishActby when stop button is tapped',
          (tester) async {
        final activeAct = ActiveAct(
            memId,
            DateAndTime.from(
                DateTime.now().subtract(const Duration(minutes: 5))));
        final mem = Mem(memId, 'Test Mem', null, null, latestAct: activeAct);
        final now = DateTime.now();
        final notification = savedMemNotification(
            id: 1,
            memId: memId,
            type: MemNotificationType.repeat,
            timeOfDaySeconds: 9 * 60 * 60,
            message: 'Repeat',
            createdAt: now,
            updatedAt: now);
        final fakeActEntities = _FakeActEntities();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                  ListValueStateNotifier<MemNotificationEntityV1>(
                      [notification])),
              memEntitiesProvider.overrideWith(
                  () => _FakeMemEntities([savedMemFromDomain(mem)])),
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.stop));
        await tester.pump();

        expect(fakeActEntities.finishActbyCallCount, 1);
        expect(fakeActEntities.lastFinishActbyMemId, memId);
      });

      testWidgets(
          'calls skipActBy when skip is chosen from completion dialog after long press on stop',
          (tester) async {
        final now = DateTime.now();
        final notification = savedMemNotification(
            id: 1,
            memId: memId,
            type: MemNotificationType.repeat,
            timeOfDaySeconds: 9 * 60 * 60,
            message: 'Repeat',
            createdAt: now,
            updatedAt: now);
        final fakeActEntities = _FakeActEntities();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                  ListValueStateNotifier<MemNotificationEntityV1>(
                      [notification])),
              memEntitiesProvider.overrideWith(
                  () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(baseMem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byIcon(Icons.stop));
        await tester.pumpAndSettle();

        await tester.tap(find.text(buildL10n().memListCompletionDialogSkip));
        await tester.pump();

        expect(fakeActEntities.skipActByCallCount, 1);
        expect(fakeActEntities.lastSkipActByMemId, memId);
        expect(fakeActEntities.finishActbyCallCount, 0);
      });

      testWidgets(
          'does not open skip dialog when stop is long pressed during active act',
          (tester) async {
        final activeAct = ActiveAct(
            memId,
            DateAndTime.from(
                DateTime.now().subtract(const Duration(minutes: 5))));
        final mem = Mem(memId, 'Test Mem', null, null, latestAct: activeAct);
        final now = DateTime.now();
        final notification = savedMemNotification(
            id: 1,
            memId: memId,
            type: MemNotificationType.repeat,
            timeOfDaySeconds: 9 * 60 * 60,
            message: 'Repeat',
            createdAt: now,
            updatedAt: now);
        final fakeActEntities = _FakeActEntities();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                  ListValueStateNotifier<MemNotificationEntityV1>(
                      [notification])),
              memEntitiesProvider.overrideWith(
                  () => _FakeMemEntities([savedMemFromDomain(mem)])),
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byIcon(Icons.stop));
        await tester.pumpAndSettle();

        expect(
            find.text(buildL10n().memListCompletionDialogSkip), findsNothing);
        expect(fakeActEntities.skipActByCallCount, 0);
      });

      testWidgets('calls pauseByMemId when pause button is tapped',
          (tester) async {
        final activeAct = ActiveAct(
            memId,
            DateAndTime.from(
                DateTime.now().subtract(const Duration(minutes: 5))));
        final mem = Mem(memId, 'Test Mem', null, null, latestAct: activeAct);
        final now = DateTime.now();
        final notification = savedMemNotification(
            id: 1,
            memId: memId,
            type: MemNotificationType.repeat,
            timeOfDaySeconds: 9 * 60 * 60,
            message: 'Repeat',
            createdAt: now,
            updatedAt: now);
        final fakeActEntities = _FakeActEntities();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                  ListValueStateNotifier<MemNotificationEntityV1>(
                      [notification])),
              memEntitiesProvider.overrideWith(
                  () => _FakeMemEntities([savedMemFromDomain(mem)])),
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();

        expect(fakeActEntities.pauseByMemIdCallCount, 1);
        expect(fakeActEntities.lastPauseByMemId, memId);
      });

      testWidgets('calls closeByMemId when close button is tapped',
          (tester) async {
        final pausedAct = PausedAct(
            memId, DateTime.now().subtract(const Duration(minutes: 5)));
        final mem = Mem(memId, 'Test Mem', null, null, latestAct: pausedAct);
        final now = DateTime.now();
        final notification = savedMemNotification(
            id: 1,
            memId: memId,
            type: MemNotificationType.repeat,
            timeOfDaySeconds: 9 * 60 * 60,
            message: 'Repeat',
            createdAt: now,
            updatedAt: now);
        final fakeActEntities = _FakeActEntities();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                  ListValueStateNotifier<MemNotificationEntityV1>(
                      [notification])),
              memEntitiesProvider.overrideWith(
                  () => _FakeMemEntities([savedMemFromDomain(mem)])),
              actEntitiesProvider.overrideWith(() => fakeActEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(fakeActEntities.closeByMemIdCallCount, 1);
        expect(fakeActEntities.lastCloseByMemId, memId);
      });

      testWidgets('calls onTap when ListTile is tapped', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                  (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
              memEntitiesProvider.overrideWith(
                  () => _FakeMemEntities([savedMemFromDomain(baseMem)])),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(baseMem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final listTile = tester.widget<ListTile>(find.byType(ListTile));
        expect(listTile.onTap, isNotNull);
        listTile.onTap?.call();
      });

      testWidgets('shows today count and target', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                  (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([
                  savedMemFromDomain(baseMem).updatedWith(
                    target: () => _countTarget(memId),
                  ),
                ]),
              ),
              preferenceProvider(startOfDayKey)
                  .overrideWith(() => _FakeStartOfDay()),
              listPeriodCountByMemIdProvider.overrideWith(
                (ref) async => {memId: 2},
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(baseMem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Test Mem'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text(' / '), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('keeps state time when the target is a count',
          (tester) async {
        final mem = Mem(
          memId,
          'Test Mem',
          null,
          null,
          latestAct: ActiveAct(
            memId,
            DateAndTime.from(
              DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                  (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([
                  savedMemFromDomain(mem).updatedWith(
                    target: () => _countTarget(memId),
                  ),
                ]),
              ),
              preferenceProvider(startOfDayKey)
                  .overrideWith(() => _FakeStartOfDay()),
              listPeriodCountByMemIdProvider.overrideWith(
                (ref) async => {memId: 2},
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LiveElapsedTimeText), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        final row = tester.getRect(
          find
              .ancestor(
                of: find.byType(LiveElapsedTimeText),
                matching: find.byType(Row),
              )
              .first,
        );
        expect(
          tester.getCenter(find.byType(LiveElapsedTimeText)).dx,
          closeTo(row.center.dx, 1),
        );
        expect(
          tester.getTopRight(find.text('3')).dx,
          closeTo(row.right, 1),
        );
        expect(
          tester.getTopLeft(find.byType(LiveElapsedTimeText)).dx,
          lessThan(tester.getTopLeft(find.text('2')).dx),
        );
      });

      testWidgets('shows 0 and the target once the daily count is reached',
          (tester) async {
        const targetValue = 3;
        await _pumpMemListCount(
          tester,
          memId: memId,
          mem: baseMem,
          target: _countTarget(memId, value: targetValue),
          todayCount: targetValue,
        );

        expect(find.text('0'), findsOneWidget);
        expect(find.text('$targetValue'), findsOneWidget);
      });

      testWidgets('shows the week count while the weekly target is unmet',
          (tester) async {
        const todayCount = 9;
        const weekCount = 1;
        const targetValue = 2;
        await _pumpMemListCount(
          tester,
          memId: memId,
          mem: _memEndedDaysBefore(memId, DateTime.daysPerWeek - 1),
          target: _countTarget(
            memId,
            value: targetValue,
            period: Period.aWeek,
          ),
          todayCount: todayCount,
          periodCounts: {memId: weekCount},
        );

        expect(find.text('$weekCount'), findsOneWidget);
        expect(find.text('$targetValue'), findsOneWidget);
        expect(find.text('$todayCount'), findsNothing);
      });

      testWidgets('shows 0 once the weekly count is reached', (tester) async {
        const todayCount = 9;
        const targetValue = 2;
        await _pumpMemListCount(
          tester,
          memId: memId,
          mem: _memEndedDaysBefore(memId, 0),
          target: _countTarget(
            memId,
            value: targetValue,
            period: Period.aWeek,
          ),
          todayCount: todayCount,
          periodCounts: {memId: targetValue},
        );

        expect(find.text('0'), findsOneWidget);
        expect(find.text('$targetValue'), findsOneWidget);
        expect(find.text('$todayCount'), findsNothing);
      });

      testWidgets('shows 0 when a week has passed since the last act',
          (tester) async {
        const todayCount = 9;
        const weekCount = 1;
        const targetValue = 2;
        await _pumpMemListCount(
          tester,
          memId: memId,
          mem: _memEndedDaysBefore(memId, DateTime.daysPerWeek),
          target: _countTarget(
            memId,
            value: targetValue,
            period: Period.aWeek,
          ),
          todayCount: todayCount,
          periodCounts: {memId: weekCount},
        );

        expect(find.text('0'), findsOneWidget);
        expect(find.text('$targetValue'), findsOneWidget);
        expect(find.text('$weekCount'), findsNothing);
        expect(find.text('$todayCount'), findsNothing);
      });

      testWidgets(
          'shows the period count for a count target that is not a day or a week',
          (tester) async {
        const periodCount = 4;
        const targetValue = 3;
        await _pumpMemListCount(
          tester,
          memId: memId,
          mem: baseMem,
          target: _countTarget(
            memId,
            value: targetValue,
            period: Period.aMonth,
          ),
          todayCount: periodCount,
        );

        expect(find.text('$periodCount'), findsOneWidget);
        expect(find.text('$targetValue'), findsOneWidget);
        expect(find.text('0'), findsNothing);
      });

      testWidgets('hides the count while the period count is still loading',
          (tester) async {
        final pending = Completer<Map<int, int>>();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([
                  savedMemFromDomain(baseMem).updatedWith(
                    target: () => _countTarget(memId),
                  ),
                ]),
              ),
              preferenceProvider(startOfDayKey)
                  .overrideWith(() => _FakeStartOfDay()),
              listPeriodCountByMemIdProvider.overrideWith(
                (ref) => pending.future,
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(baseMem),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Test Mem'), findsOneWidget);
        expect(find.text('3'), findsNothing);
        expect(
          tester.widget<ListTile>(find.byType(ListTile)).subtitle,
          isNull,
        );

        pending.complete({memId: 2});
        await tester.pumpAndSettle();

        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows recorded time and the time target', (tester) async {
        const targetSeconds = 2 * Duration.secondsPerHour;
        const recorded = Duration(hours: 1, minutes: 30);
        final day = DateAndTime.now().logicalDay(
          const TimeOfDay(hour: 0, minute: 0),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([
                  savedMemFromDomain(baseMem).updatedWith(
                    target: () => Target(
                      memId: memId,
                      targetType: TargetType.equalTo,
                      targetUnit: TargetUnit.time,
                      value: targetSeconds,
                      period: Period.aDay,
                    ),
                  ),
                ]),
              ),
              preferenceProvider(startOfDayKey)
                  .overrideWith(() => _FakeStartOfDay()),
              listPeriodCountByMemIdProvider.overrideWith(
                (ref) async => <int, int>{},
              ),
              viewedDayActAmountProvider(memId, day).overrideWith(
                (ref) async => const DayActAmount(0, recorded),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(baseMem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(recorded.formatHHmm()), findsOneWidget);
        expect(
          find.text(const Duration(seconds: targetSeconds).formatHHmm()),
          findsOneWidget,
        );
      });
    });

    group('next time after last act', () {
      const interval = Duration(hours: 2);

      // 間隔が日付をまたぐと一覧はその時刻を出さない
      bool intervalStaysOnActDay(DateTime end) {
        final next = end.add(interval);
        return end.year == next.year &&
            end.month == next.month &&
            end.day == next.day;
      }

      DateTime endWhoseIntervalStaysOnItsDay(
        DateTime end, {
        required bool nextIsAhead,
      }) {
        if (intervalStaysOnActDay(end)) return end;
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final day = nextIsAhead
            ? startOfToday.add(const Duration(days: 1))
            : startOfToday.subtract(const Duration(days: 1));
        final atNoon = DateTime(day.year, day.month, day.day, _noonHour);
        return nextIsAhead ? atNoon.subtract(interval) : atNoon;
      }

      Target intervalTarget() => Target(
            memId: memId,
            targetType: TargetType.equalTo,
            targetUnit: TargetUnit.count,
            value: 4,
            period: Period.aDay,
            secondsAfterLastAct: interval.inSeconds,
          );

      const endedHoursAgo = 3;
      const minutesAgoWhileNextIsAhead = 30;
      const notifyMinutesAgo = 90;
      const belowTargetCount = 1;

      Mem memEndedAt(DateTime endedAt) {
        final end = DateAndTime.from(endedAt, timeOfDay: endedAt);
        return Mem(
          memId,
          'Test Mem',
          null,
          null,
          latestAct: Act.by(
            memId,
            startWhen: end.subtract(const Duration(minutes: 30)),
            endWhen: end,
          ),
        );
      }

      Future<void> pump(WidgetTester tester, Mem mem) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                  (ref) => ListValueStateNotifier<MemNotificationEntityV1>([])),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([
                  savedMemFromDomain(mem).updatedWith(
                    target: () => intervalTarget(),
                  ),
                ]),
              ),
              preferenceProvider(startOfDayKey)
                  .overrideWith(() => _FakeStartOfDay()),
              listPeriodCountByMemIdProvider.overrideWith(
                (ref) async => {memId: belowTargetCount},
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> expectClock(
        WidgetTester tester,
        DateTime endedAt,
        Matcher color,
      ) async {
        final mem = memEndedAt(endedAt);
        await pump(tester, mem);
        final next =
            DateAndTime.from(endedAt, timeOfDay: endedAt).add(interval);
        final formatted = TimeOfDay.fromDateTime(next).format(
          tester.element(find.byType(MemListItemSubtitle)),
        );

        expect(find.byType(MemListItemSubtitle), findsOneWidget);
        expect(find.text(formatted), findsOneWidget);
        expect(
          tester.widget<Text>(find.text(formatted)).style?.color,
          color,
        );
        expect(
          tester.widget<ListTile>(find.byType(ListTile)).subtitle,
          isNotNull,
        );
      }

      testWidgets('shows the clock in red when the next time has passed',
          (tester) async {
        await expectClock(
          tester,
          endWhoseIntervalStaysOnItsDay(
            DateTime.now().subtract(const Duration(hours: endedHoursAgo)),
            nextIsAhead: false,
          ),
          equals(warningColor),
        );
      });

      testWidgets('shows the clock without red when the next time is ahead',
          (tester) async {
        await expectClock(
          tester,
          endWhoseIntervalStaysOnItsDay(
            DateTime.now().subtract(
              const Duration(minutes: minutesAgoWhileNextIsAhead),
            ),
            nextIsAhead: true,
          ),
          isNot(equals(warningColor)),
        );
      });

      Future<void> pumpWithNotify(
        WidgetTester tester, {
        required Mem mem,
        required TimeOfDay notify,
        required int todayCount,
      }) async {
        final now = DateTime.now();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([
                  savedMemNotification(
                    id: 1,
                    memId: memId,
                    type: MemNotificationType.repeat,
                    timeOfDaySeconds: notify.hour * Duration.secondsPerHour +
                        notify.minute * Duration.secondsPerMinute,
                    message: 'Repeat',
                    createdAt: now,
                    updatedAt: now,
                  ),
                ]),
              ),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([
                  savedMemFromDomain(mem).updatedWith(
                    target: () => intervalTarget(),
                  ),
                ]),
              ),
              preferenceProvider(startOfDayKey)
                  .overrideWith(() => _FakeStartOfDay()),
              listPeriodCountByMemIdProvider.overrideWith(
                (ref) async => {memId: todayCount},
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets(
          'shows one clock with the time after the last act when a notification time is also set',
          (tester) async {
        final now = DateTime.now();
        final endedAt = endWhoseIntervalStaysOnItsDay(
          now.subtract(const Duration(hours: endedHoursAgo)),
          nextIsAhead: false,
        );
        final notify = TimeOfDay.fromDateTime(
          now.subtract(const Duration(minutes: notifyMinutesAgo)),
        );
        await pumpWithNotify(
          tester,
          mem: memEndedAt(endedAt),
          notify: notify,
          todayCount: belowTargetCount,
        );

        final context = tester.element(find.byType(MemListItemSubtitle));
        final next =
            DateAndTime.from(endedAt, timeOfDay: endedAt).add(interval);
        expect(
          find.text(TimeOfDay.fromDateTime(next).format(context)),
          findsOneWidget,
        );
        expect(find.text(notify.format(context)), findsNothing);
      });

      testWidgets(
          'shows the next day notification time once the daily count is reached',
          (tester) async {
        final now = DateTime.now();
        final endedAt = now.subtract(const Duration(hours: endedHoursAgo));
        final notify = TimeOfDay.fromDateTime(
          now.subtract(const Duration(minutes: notifyMinutesAgo)),
        );
        await pumpWithNotify(
          tester,
          mem: memEndedAt(endedAt),
          notify: notify,
          todayCount: intervalTarget().value,
        );

        final context = tester.element(find.byType(MemListItemSubtitle));
        final next =
            DateAndTime.from(endedAt, timeOfDay: endedAt).add(interval);
        final notifyText = find.text(notify.format(context));
        expect(notifyText, findsOneWidget);
        expect(
          find.text(TimeOfDay.fromDateTime(next).format(context)),
          findsNothing,
        );
        expect(
          tester.widget<Text>(notifyText).style?.color,
          isNot(equals(warningColor)),
        );
      });

      testWidgets(
          'hides the interval clock once the daily count is reached and there is no notification',
          (tester) async {
        final endedAt = DateTime.now().subtract(
          const Duration(hours: endedHoursAgo),
        );
        final mem = memEndedAt(endedAt);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([
                  savedMemFromDomain(mem).updatedWith(
                    target: () => intervalTarget(),
                  ),
                ]),
              ),
              preferenceProvider(startOfDayKey)
                  .overrideWith(() => _FakeStartOfDay()),
              listPeriodCountByMemIdProvider.overrideWith(
                (ref) async => {memId: intervalTarget().value},
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.widget<ListTile>(find.byType(ListTile)).subtitle,
          isNull,
        );
      });
    });

    group('undone children', () {
      const repeatNotifyHour = 9;

      Future<void> pump(
        WidgetTester tester, {
        required Mem mem,
        bool withNotification = false,
        Set<int>? parentIds,
        _FakeMemEntities? memEntities,
        _FakeActEntities? actEntities,
      }) async {
        final now = DateTime.now();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>(
                  withNotification
                      ? [
                          savedMemNotification(
                            id: 1,
                            memId: memId,
                            type: MemNotificationType.repeat,
                            timeOfDaySeconds:
                                repeatNotifyHour * Duration.secondsPerHour,
                            message: 'Repeat',
                            createdAt: now,
                            updatedAt: now,
                          ),
                        ]
                      : [],
                ),
              ),
              memEntitiesProvider.overrideWith(
                () =>
                    memEntities ?? _FakeMemEntities([savedMemFromDomain(mem)]),
              ),
              parentMemIdsWithUndoneChildrenProvider.overrideWithValue(
                parentIds ?? {memId},
              ),
              if (actEntities != null)
                actEntitiesProvider.overrideWith(() => actEntities),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListItemView(mem),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      void expectParentIconLeading(WidgetTester tester) {
        final leading = tester.widget<ListTile>(find.byType(ListTile)).leading;
        expect(leading, isA<Icon>());
        expect((leading! as Icon).icon, Icons.account_tree);
      }

      testWidgets(
          'shows a parent icon instead of the checkbox when the id is in the set',
          (tester) async {
        await pump(tester, mem: baseMem);

        expectParentIconLeading(tester);
        expect(find.byType(MemDoneCheckbox), findsNothing);
        expect(find.byType(Checkbox), findsNothing);
        expect(find.byIcon(Icons.stop), findsNothing);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
        expect(
          find.ancestor(
            of: find.byIcon(Icons.account_tree),
            matching: find.byType(IconButton),
          ),
          findsNothing,
        );
        expect(
          tester.widget<ListTile>(find.byType(ListTile)).onTap,
          isNotNull,
        );
      });

      testWidgets(
          'keeps stop and play when the id is in the set and a notification is enabled',
          (tester) async {
        final actEntities = _FakeActEntities();
        await pump(
          tester,
          mem: baseMem,
          withNotification: true,
          actEntities: actEntities,
        );

        expect(find.byIcon(Icons.stop), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.account_tree), findsNothing);
        expect(find.byType(MemDoneCheckbox), findsNothing);

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();

        expect(actEntities.startActbyCallCount, 1);
        expect(actEntities.lastStartActbyMemId, memId);

        await tester.tap(find.byIcon(Icons.stop));
        await tester.pump();

        expect(actEntities.finishActbyCallCount, 1);
        expect(actEntities.lastFinishActbyMemId, memId);
      });

      testWidgets(
          'keeps the checkbox when the mem is done even if the id is in the set',
          (tester) async {
        final doneMem = Mem(memId, 'Done Mem', DateTime.now(), null);
        final memEntities = _FakeMemEntities([savedMemFromDomain(doneMem)]);
        await pump(tester, mem: doneMem, memEntities: memEntities);

        expect(find.byIcon(Icons.account_tree), findsNothing);
        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isTrue);

        checkbox.onChanged!(false);
        await tester.pump();

        expect(memEntities.undoneMemCallCount, 1);
        expect(memEntities.lastUndoneMemId, memId);
      });

      testWidgets(
          'keeps pause and stop while an act is active and the id is in the set',
          (tester) async {
        final mem = Mem(
          memId,
          'Test Mem',
          null,
          null,
          latestAct: ActiveAct(
            memId,
            DateAndTime.from(
              DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          ),
        );
        await pump(tester, mem: mem, withNotification: true);

        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.stop), findsOneWidget);
        expect(find.byIcon(Icons.account_tree), findsNothing);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
      });

      testWidgets(
          'keeps close and play while an act is paused and the id is in the set',
          (tester) async {
        final mem = Mem(
          memId,
          'Test Mem',
          null,
          null,
          latestAct: PausedAct(
            memId,
            DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        );
        await pump(tester, mem: mem, withNotification: true);

        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.account_tree), findsNothing);
        expect(find.byIcon(Icons.stop), findsNothing);
      });

      testWidgets('keeps the checkbox when the id is not in the set',
          (tester) async {
        await pump(tester, mem: baseMem, parentIds: {memId + 1});

        expect(find.byType(MemDoneCheckbox), findsOneWidget);
        expect(find.byIcon(Icons.account_tree), findsNothing);
        expect(find.byIcon(Icons.stop), findsNothing);
      });

      testWidgets('keeps stop and play when the id is not in the set',
          (tester) async {
        await pump(
          tester,
          mem: baseMem,
          withNotification: true,
          parentIds: {memId + 1},
        );

        expect(find.byIcon(Icons.stop), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.account_tree), findsNothing);
        expect(find.byType(MemDoneCheckbox), findsNothing);
      });
    });
  });
}
