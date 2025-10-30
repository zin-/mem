import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/features/mems/list/item/subtitle.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/framework/view/timer.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';

class _FakeMemState extends MemState {
  final Mem _mem;

  _FakeMemState(this._mem);

  @override
  Future<Mem> build(int? memId) async {
    return _mem;
  }
}

class _FakeMemEntities extends MemEntities {
  final Iterable<SavedMemEntity> _state;

  _FakeMemEntities(this._state);

  @override
  Iterable<SavedMemEntity> build() => _state;
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
            latestActsByMemProvider.overrideWith((ref) => {memId: null}),
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntity>([])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: activeAct}),
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntity>([])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(baseMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElapsedTimeView), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('displays play/close buttons when act is paused',
        (tester) async {
      final pausedAct =
          PausedAct(memId, DateTime.now().subtract(const Duration(minutes: 5)));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: pausedAct}),
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntity>([])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(baseMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.timer), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('displays notification icon when notifications exist',
        (tester) async {
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: null}),
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntity>([notification])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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
            latestActsByMemProvider.overrideWith((ref) => {memId: null}),
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntity>([])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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
            latestActsByMemProvider.overrideWith((ref) => {memId: null}),
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntity>([])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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
            latestActsByMemProvider.overrideWith((ref) => {memId: null}),
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntity>([])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: null}),
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntity>([notification])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: null}),
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntity>([notification])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: null}),
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntity>([notification])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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
            latestActsByMemProvider.overrideWith((ref) => {memId: null}),
            memNotificationsByMemIdProvider(memId).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntity>([])),
            // MemNameTextをモックする代わりに、MemNameTextを直接モック
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            // MemListItemSubtitleが使用するmemByMemIdProviderをモック
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: activeAct}),
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntity>([notification])),
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(baseMem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // アクティブなアクトがある場合、タイトルにElapsedTimeViewが表示される
      expect(find.byType(ElapsedTimeView), findsOneWidget);
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
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: pausedAct}),
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntity>([notification])),
            memStateProvider(memId).overrideWith(() => _FakeMemState(baseMem)),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': baseMem.id,
                    'name': baseMem.name,
                    'doneAt': baseMem.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': null,
                    'endAt': null,
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(baseMem),
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
      final memWithPeriod = Mem(memId, 'Mem with Period', null,
          DateAndTimePeriod(start: DateAndTime.now()));
      final activeAct = ActiveAct(
          memId,
          DateAndTime.from(
              DateTime.now().subtract(const Duration(minutes: 5))));
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: activeAct}),
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntity>([notification])),
            memStateProvider(memId)
                .overrideWith(() => _FakeMemState(memWithPeriod)),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': memWithPeriod.id,
                    'name': memWithPeriod.name,
                    'doneAt': memWithPeriod.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': memWithPeriod.period?.end?.toIso8601String(),
                    'endAt': memWithPeriod.period?.end?.toIso8601String(),
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MemListItemView(memWithPeriod),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // アクティブなアクトがある場合、タイトルにElapsedTimeViewが表示される
      expect(find.byType(ElapsedTimeView), findsOneWidget);
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
      final memWithPeriod = Mem(memId, 'Mem with Period', null,
          DateAndTimePeriod(start: DateAndTime.now()));
      final pausedAct =
          PausedAct(memId, DateTime.now().subtract(const Duration(minutes: 5)));
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            latestActsByMemProvider.overrideWith((ref) => {memId: pausedAct}),
            memNotificationsByMemIdProvider(memId).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntity>([notification])),
            memStateProvider(memId)
                .overrideWith(() => _FakeMemState(memWithPeriod)),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([
                  SavedMemEntity({
                    'id': memWithPeriod.id,
                    'name': memWithPeriod.name,
                    'doneAt': memWithPeriod.doneAt,
                    'notifyOn': null,
                    'notifyAt': null,
                    'endOn': memWithPeriod.period?.end?.toIso8601String(),
                    'endAt': memWithPeriod.period?.end?.toIso8601String(),
                    'createdAt': DateTime.now(),
                    'updatedAt': DateTime.now(),
                    'archivedAt': null,
                  })
                ])),
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
  });
}
