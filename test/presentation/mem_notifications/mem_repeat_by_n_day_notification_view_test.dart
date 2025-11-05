import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_repeat_by_n_day_notification_view.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';

Widget _buildTestApp(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => buildL10n(context).test,
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  group('MemRepeatByNDayNotificationView', () {
    testWidgets('displays TextFormField with nDay value when nDay is set',
        (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeatByNDay',
        defColMemNotificationsTime.name: 3,
        defColMemNotificationsMessage.name: 'Repeat by 3 days',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final listNotifier = ListValueStateNotifier<MemNotificationEntity>([
        notification
      ]);
      final valueNotifier =
          ValueStateNotifier<MemNotificationEntity>(notification);

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatByNDayNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) => listNotifier),
            memRepeatByNDayNotificationByMemIdProvider(1).overrideWith(
              (ref) => valueNotifier,
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyMemRepeatByNDayNotification), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.initialValue, '3');
    });

    testWidgets('displays TextFormField with 0 when nDay is null',
        (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeatByNDay',
        defColMemNotificationsTime.name: null,
        defColMemNotificationsMessage.name: 'Repeat by N days',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final listNotifier = ListValueStateNotifier<MemNotificationEntity>([
        notification
      ]);
      final valueNotifier =
          ValueStateNotifier<MemNotificationEntity>(notification);

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatByNDayNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) => listNotifier),
            memRepeatByNDayNotificationByMemIdProvider(1).overrideWith(
              (ref) => valueNotifier,
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyMemRepeatByNDayNotification), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.initialValue, '0');
    });

    testWidgets('calls onNDayChanged when value is entered', (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeatByNDay',
        defColMemNotificationsTime.name: 3,
        defColMemNotificationsMessage.name: 'Repeat by 3 days',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final listNotifier = ListValueStateNotifier<MemNotificationEntity>([
        notification
      ]);
      final valueNotifier =
          ValueStateNotifier<MemNotificationEntity>(notification);

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatByNDayNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) => listNotifier),
            memRepeatByNDayNotificationByMemIdProvider(1).overrideWith(
              (ref) => valueNotifier,
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyMemRepeatByNDayNotification), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      final initialTextField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(initialTextField.initialValue, '3');

      await tester.enterText(find.byType(TextFormField), '5');
      await tester.pump();
    });

    testWidgets('calls onNDayChanged with 1 when value is empty',
        (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeatByNDay',
        defColMemNotificationsTime.name: 3,
        defColMemNotificationsMessage.name: 'Repeat by 3 days',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final listNotifier = ListValueStateNotifier<MemNotificationEntity>([
        notification
      ]);
      final valueNotifier =
          ValueStateNotifier<MemNotificationEntity>(notification);

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatByNDayNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) => listNotifier),
            memRepeatByNDayNotificationByMemIdProvider(1).overrideWith(
              (ref) => valueNotifier,
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyMemRepeatByNDayNotification), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
    });

    testWidgets('calls onNDayChanged with null when value is 0',
        (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeatByNDay',
        defColMemNotificationsTime.name: 3,
        defColMemNotificationsMessage.name: 'Repeat by 3 days',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final listNotifier = ListValueStateNotifier<MemNotificationEntity>([
        notification
      ]);
      final valueNotifier =
          ValueStateNotifier<MemNotificationEntity>(notification);

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatByNDayNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) => listNotifier),
            memRepeatByNDayNotificationByMemIdProvider(1).overrideWith(
              (ref) => valueNotifier,
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyMemRepeatByNDayNotification), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '0');
      await tester.pump();
    });

    testWidgets('handles memId null', (tester) async {
      final now = DateTime.now();
      final notification = SavedMemNotificationEntity({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: null,
        defColMemNotificationsType.name: 'repeatByNDay',
        defColMemNotificationsTime.name: 3,
        defColMemNotificationsMessage.name: 'Repeat by 3 days',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final listNotifier = ListValueStateNotifier<MemNotificationEntity>([
        notification
      ]);
      final valueNotifier =
          ValueStateNotifier<MemNotificationEntity>(notification);

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatByNDayNotificationView(null),
          overrides: [
            memNotificationsByMemIdProvider(null)
                .overrideWith((ref) => listNotifier),
            memRepeatByNDayNotificationByMemIdProvider(null).overrideWith(
              (ref) => valueNotifier,
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyMemRepeatByNDayNotification), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}

