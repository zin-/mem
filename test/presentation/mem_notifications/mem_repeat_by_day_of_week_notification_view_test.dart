import 'package:day_picker/day_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_repeat_by_day_of_week_notification_view.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';

import '../../entity_factories.dart';

Widget _buildTestApp(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      onGenerateTitle: (context) => buildL10n(context).test,
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

SavedMemNotificationEntityV1 _dayOfWeekNotification({
  required int? memId,
  required int weekday,
}) {
  final now = DateTime.now();
  return savedMemNotification(
    id: weekday,
    memId: memId,
    type: MemNotificationType.repeatByDayOfWeek,
    timeOfDaySeconds: weekday,
    message: 'Repeat by day of week',
    createdAt: now,
    updatedAt: now,
  );
}

Future<ListValueStateNotifier<MemNotificationEntityV1>> _pumpView(
  WidgetTester tester, {
  required int? memId,
  required List<SavedMemNotificationEntityV1> notifications,
}) async {
  final listNotifier =
      ListValueStateNotifier<MemNotificationEntityV1>(notifications);
  await tester.pumpWidget(
    _buildTestApp(
      MemRepeatByDaysOfWeekNotificationView(memId),
      overrides: [
        memNotificationsByMemIdProvider(memId)
            .overrideWith((ref) => listNotifier),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return listNotifier;
}

void main() {
  group('MemRepeatByDaysOfWeekNotificationView', () {
    testWidgets('shows English weekday chips from Sunday', (tester) async {
      await _pumpView(
        tester,
        memId: 1,
        notifications: [
          _dayOfWeekNotification(memId: 1, weekday: DateTime.monday),
        ],
      );

      final selectWeekDays = tester.widget<SelectWeekDays>(
        find.byType(SelectWeekDays),
      );
      expect(
        selectWeekDays.days.map((e) => e.dayKey),
        [
          DateTime.sunday,
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
        ].map((weekday) => weekday.toString()),
      );
      expect(
        selectWeekDays.days.map((e) => e.dayName),
        ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      );
      expect(
        selectWeekDays.days.singleWhere((e) => e.dayKey == '1').isSelected,
        isTrue,
      );
    });

    testWidgets('adds tapped weekday', (tester) async {
      final listNotifier = await _pumpView(
        tester,
        memId: 1,
        notifications: [
          _dayOfWeekNotification(memId: 1, weekday: DateTime.monday),
        ],
      );

      await tester.tap(find.text('Tue'));
      await tester.pump();

      expect(
        listNotifier.state
            .where((e) => e.value.isRepeatByDayOfWeek())
            .map((e) => e.value.time),
        containsAll([DateTime.monday, DateTime.tuesday]),
      );
    });

    testWidgets('removes tapped weekday', (tester) async {
      final listNotifier = await _pumpView(
        tester,
        memId: 1,
        notifications: [
          _dayOfWeekNotification(memId: 1, weekday: DateTime.monday),
          _dayOfWeekNotification(memId: 1, weekday: DateTime.tuesday),
        ],
      );

      await tester.tap(find.text('Mon'));
      await tester.pump();

      expect(
        listNotifier.state
            .where((e) => e.value.isRepeatByDayOfWeek())
            .map((e) => e.value.time),
        [DateTime.tuesday],
      );
    });
  });
}
