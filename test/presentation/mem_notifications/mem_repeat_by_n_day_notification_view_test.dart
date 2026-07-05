import 'package:flutter/material.dart';
import '../../entity_factories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
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

SavedMemNotificationEntityV1 _repeatByNDayNotification({
  required int? memId,
  int? timeOfDaySeconds,
}) {
  final now = DateTime.now();
  return savedMemNotification(
    id: 1,
    memId: memId,
    type: MemNotificationType.repeatByNDay,
    timeOfDaySeconds: timeOfDaySeconds,
    message: 'Repeat by N days',
    createdAt: now,
    updatedAt: now,
  );
}

Future<ListValueStateNotifier<MemNotificationEntityV1>> _pumpView(
  WidgetTester tester, {
  required int? memId,
  required SavedMemNotificationEntityV1 notification,
  bool linkRepeatProvider = true,
}) async {
  final listNotifier =
      ListValueStateNotifier<MemNotificationEntityV1>([notification]);
  final overrides = <Override>[
    memNotificationsByMemIdProvider(memId).overrideWith((ref) => listNotifier),
  ];

  if (linkRepeatProvider) {
    overrides.add(
      memRepeatByNDayNotificationByMemIdProvider(memId).overrideWith(
        (ref) => ValueStateNotifier<MemNotificationEntityV1>(notification),
      ),
    );
  }

  await tester.pumpWidget(
    _buildTestApp(
      MemRepeatByNDayNotificationView(memId),
      overrides: overrides,
    ),
  );
  await tester.pumpAndSettle();

  return listNotifier;
}

TextFormField _textField(WidgetTester tester) =>
    tester.widget<TextFormField>(find.byType(TextFormField));

void main() {
  group('MemRepeatByNDayNotificationView', () {
    testWidgets('displays nDay value when set', (tester) async {
      await _pumpView(
        tester,
        memId: 1,
        notification: _repeatByNDayNotification(memId: 1, timeOfDaySeconds: 3),
      );

      expect(find.byKey(keyMemRepeatByNDayNotification), findsOneWidget);
      expect(_textField(tester).controller!.text, '3');
    });

    testWidgets('displays empty field when nDay is null', (tester) async {
      await _pumpView(
        tester,
        memId: 1,
        notification: _repeatByNDayNotification(memId: 1),
      );

      expect(find.byKey(keyMemRepeatByNDayNotification), findsOneWidget);
      expect(_textField(tester).controller!.text, '');
    });

    testWidgets(
        'keeps cleared field while typing new value through provider rebuild',
        (tester) async {
      await _pumpView(
        tester,
        memId: 1,
        notification: _repeatByNDayNotification(memId: 1, timeOfDaySeconds: 3),
        linkRepeatProvider: false,
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '7',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();

      expect(_textField(tester).controller!.text, '7');
    });

    testWidgets('accepts entered value', (tester) async {
      await _pumpView(
        tester,
        memId: 1,
        notification: _repeatByNDayNotification(memId: 1, timeOfDaySeconds: 3),
      );

      expect(_textField(tester).controller!.text, '3');

      await tester.enterText(find.byType(TextFormField), '5');
      await tester.pump();
    });

    testWidgets('commits null when empty input is completed', (tester) async {
      final listNotifier = await _pumpView(
        tester,
        memId: 1,
        notification: _repeatByNDayNotification(memId: 1, timeOfDaySeconds: 3),
        linkRepeatProvider: false,
      );

      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();

      expect(listNotifier.state.single.value.time, isNull);
      expect(_textField(tester).controller!.text, '');
    });

    testWidgets('commits null when empty input loses focus', (tester) async {
      final listNotifier = await _pumpView(
        tester,
        memId: 1,
        notification: _repeatByNDayNotification(memId: 1, timeOfDaySeconds: 3),
        linkRepeatProvider: false,
      );

      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump();

      expect(listNotifier.state.single.value.time, isNull);
      expect(_textField(tester).controller!.text, '');
    });

    testWidgets('clears field when 0 is entered', (tester) async {
      final listNotifier = await _pumpView(
        tester,
        memId: 1,
        notification: _repeatByNDayNotification(memId: 1, timeOfDaySeconds: 3),
        linkRepeatProvider: false,
      );

      await tester.enterText(find.byType(TextFormField), '0');
      await tester.pump();
      await tester.pump();

      expect(listNotifier.state.single.value.time, isNull);
      expect(_textField(tester).controller!.text, '');
    });

    testWidgets('handles memId null', (tester) async {
      await _pumpView(
        tester,
        memId: null,
        notification:
            _repeatByNDayNotification(memId: null, timeOfDaySeconds: 3),
      );

      expect(find.byKey(keyMemRepeatByNDayNotification), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}
