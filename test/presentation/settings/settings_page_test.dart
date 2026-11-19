import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/settings/app_version.dart';
import 'package:mem/features/settings/app_version_client.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/features/settings/page.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference.dart';
import 'package:mem/features/settings/preference/repository.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mockito/mockito.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../helpers.mocks.dart';

class _TestConstants {
  static const int startOfDayLabelIndex = 0;
  static const int startOfDayValueIndex = 1;
  static const int notifyAfterInactivityLabelIndex = 2;
  static const int notifyAfterInactivityValueIndex = 3;
  static const int habitualMemsCountLabelIndex = 4;
  static const int habitualMemsCountValueIndex = 5;
  static const int habitualMemsCountTileIndex = 2;
  static const int habitualMemsCountMin = 1;
  static const int selectedHabitualMemsCount = 5;
  static const int habitualMemsTimeRadiusLabelIndex = 6;
  static const int habitualMemsTimeRadiusValueIndex = 7;
  static const int habitualMemsTimeRadiusTileIndex = 3;
  // 時間。初期値 1 ではなく、ピッカーの 1〜12 に入る
  static const int selectedHabitualMemsTimeRadius = 4;
  static const int habitualMemsLookbackLabelIndex = 8;
  static const int habitualMemsLookbackValueIndex = 9;
  static const int habitualMemsLookbackTileIndex = 4;
  // 日。初期値 28 ではなく、ピッカーの 1〜90 に入る
  static const int selectedHabitualMemsLookback = 10;
  static const int resetNotificationLabelIndex = 10;
  static const int appBarTitleIndex = 16;
}

Widget _createTestWidget() {
  return ProviderScope(
    child: MaterialApp(home: SettingsPage()),
  );
}

Future<void> _pumpAndSettle(WidgetTester tester) async {
  await tester.pumpWidget(_createTestWidget());
  await tester.pumpAndSettle();
}

void _verifyMultipleTextWidgets(WidgetTester tester, List<int> indices) {
  for (final index in indices) {
    final textWidget = tester.widget<Text>(find.byType(Text).at(index));
    expect(textWidget.data, isNotNull);
    expect(textWidget.data, isNotEmpty);
  }
}

class _StubAppVersionClient implements AppVersionClient {
  @override
  Future<AppVersion?> current() async => AppVersion.of(
        version: '0.5.36',
        buildNumber: '1',
      );
}

void main() {
  final mockedPreferenceRepository = MockPreferenceRepository();

  PreferenceRepository(mock: mockedPreferenceRepository);
  AppVersionClient(mock: _StubAppVersionClient());

  setUp(() {
    reset(mockedPreferenceRepository);

    when(mockedPreferenceRepository.shipByKey(startOfDayKey))
        .thenAnswer((_) async => PreferenceEntity(
              startOfDayKey,
              defaultStartOfDay,
            ));
    when(mockedPreferenceRepository.shipByKey(notifyAfterInactivity))
        .thenAnswer((_) async => PreferenceEntity(
              notifyAfterInactivity,
              defaultNotifyAfterInactivity,
            ));
    when(mockedPreferenceRepository.shipByKey(habitualMemsCountKey))
        .thenAnswer((_) async => PreferenceEntity(
              habitualMemsCountKey,
              defaultHabitualMemsCount,
            ));
    when(mockedPreferenceRepository.shipByKey(habitualMemsTimeRadiusKey))
        .thenAnswer((_) async => PreferenceEntity(
              habitualMemsTimeRadiusKey,
              defaultHabitualMemsTimeRadius,
            ));
    when(mockedPreferenceRepository.shipByKey(habitualMemsLookbackKey))
        .thenAnswer((_) async => PreferenceEntity(
              habitualMemsLookbackKey,
              defaultHabitualMemsLookback,
            ));

    when(mockedPreferenceRepository.receive(any)).thenAnswer((_) async => true);
  });

  group('SettingsPage test', () {
    group('should display', () {
      testWidgets('basic structure.', (tester) async {
        final l10n = buildL10n();
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);

        expect(
          tester
              .widget<Text>(textWidgets.at(_TestConstants.startOfDayLabelIndex))
              .data,
          equals(l10n.startOfDayLabel),
        );

        expect(
          tester
              .widget<Text>(textWidgets
                  .at(_TestConstants.notifyAfterInactivityLabelIndex))
              .data,
          equals(l10n.notifyAfterInactivityLabel),
        );

        expect(
          tester
              .widget<Text>(
                  textWidgets.at(_TestConstants.habitualMemsCountLabelIndex))
              .data,
          equals(l10n.habitualMemsCountLabel),
        );

        expect(
          tester
              .widget<Text>(textWidgets
                  .at(_TestConstants.habitualMemsTimeRadiusLabelIndex))
              .data,
          equals(l10n.habitualMemsTimeRadiusLabel),
        );

        expect(
          tester
              .widget<Text>(textWidgets
                  .at(_TestConstants.habitualMemsLookbackLabelIndex))
              .data,
          equals(l10n.habitualMemsLookbackLabel),
        );

        expect(
          tester
              .widget<Text>(
                  textWidgets.at(_TestConstants.resetNotificationLabelIndex))
              .data,
          equals(l10n.resetNotificationLabel),
        );

        expect(
          tester
              .widget<Text>(textWidgets.at(_TestConstants.appBarTitleIndex))
              .data,
          equals(l10n.settingsPageTitle),
        );

        expect(find.text(l10n.versionLabel), findsOneWidget);
        expect(find.text('0.5.36+1'), findsOneWidget);

        _verifyMultipleTextWidgets(tester, [
          _TestConstants.startOfDayValueIndex,
          _TestConstants.notifyAfterInactivityValueIndex,
          _TestConstants.habitualMemsCountValueIndex,
          _TestConstants.habitualMemsTimeRadiusValueIndex,
          _TestConstants.habitualMemsLookbackValueIndex,
        ]);
      });

      testWidgets('correct values.', (tester) async {
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);

        final startOfDayValue = tester
            .widget<Text>(textWidgets.at(_TestConstants.startOfDayValueIndex))
            .data;
        expect(startOfDayValue, equals('12:00 AM'));

        final notifyAfterInactivityValue = tester
            .widget<Text>(
                textWidgets.at(_TestConstants.notifyAfterInactivityValueIndex))
            .data;
        expect(notifyAfterInactivityValue, equals('1 h 0 m'));

        final habitualMemsCountValue = tester
            .widget<Text>(
                textWidgets.at(_TestConstants.habitualMemsCountValueIndex))
            .data;
        expect(
          habitualMemsCountValue,
          equals('$defaultHabitualMemsCount'),
        );

        final habitualMemsTimeRadiusValue = tester
            .widget<Text>(
                textWidgets.at(_TestConstants.habitualMemsTimeRadiusValueIndex))
            .data;
        expect(
          habitualMemsTimeRadiusValue,
          equals('$defaultHabitualMemsTimeRadius'),
        );

        final habitualMemsLookbackValue = tester
            .widget<Text>(
                textWidgets.at(_TestConstants.habitualMemsLookbackValueIndex))
            .data;
        expect(
          habitualMemsLookbackValue,
          equals('$defaultHabitualMemsLookback'),
        );
      });
    });

    group('should change', () {
      testWidgets('start of day value.', (tester) async {
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);
        final startOfDayValue = tester
            .widget<Text>(textWidgets.at(_TestConstants.startOfDayValueIndex))
            .data;
        expect(startOfDayValue, equals('12:00 AM'));

        await tester.tap(find.byType(SettingsTile).first);
        await tester.pumpAndSettle();

        expect(find.byType(TimePickerDialog), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(TimePickerDialog), findsNothing);
      });

      testWidgets('notify after inactivity value.', (tester) async {
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);
        final notifyAfterInactivityValue = tester
            .widget<Text>(
                textWidgets.at(_TestConstants.notifyAfterInactivityValueIndex))
            .data;
        expect(notifyAfterInactivityValue, equals('1 h 0 m'));

        await tester.tap(find.byType(SettingsTile).at(1));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);
      });

      testWidgets('habitual mems count value.', (tester) async {
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);
        final habitualMemsCountValue = tester
            .widget<Text>(
                textWidgets.at(_TestConstants.habitualMemsCountValueIndex))
            .data;
        expect(
          habitualMemsCountValue,
          equals('$defaultHabitualMemsCount'),
        );

        await tester.tap(
          find
              .byType(SettingsTile)
              .at(_TestConstants.habitualMemsCountTileIndex),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);

        final controller = tester
            .widget<ListWheelScrollView>(find.byType(ListWheelScrollView))
            .controller! as FixedExtentScrollController;
        controller.jumpToItem(
          _TestConstants.selectedHabitualMemsCount -
              _TestConstants.habitualMemsCountMin,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);

        final captured = verify(mockedPreferenceRepository.receive(captureAny))
            .captured
            .single as PreferenceEntity;
        expect(captured.key, habitualMemsCountKey);
        expect(captured.value, _TestConstants.selectedHabitualMemsCount);

        expect(
          tester
              .widget<Text>(find
                  .byType(Text)
                  .at(_TestConstants.habitualMemsCountValueIndex))
              .data,
          equals('${_TestConstants.selectedHabitualMemsCount}'),
        );
      });

      testWidgets('habitual mems time radius value.', (tester) async {
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);
        final habitualMemsTimeRadiusValue = tester
            .widget<Text>(
                textWidgets.at(_TestConstants.habitualMemsTimeRadiusValueIndex))
            .data;
        expect(
          habitualMemsTimeRadiusValue,
          equals('$defaultHabitualMemsTimeRadius'),
        );

        await tester.tap(
          find
              .byType(SettingsTile)
              .at(_TestConstants.habitualMemsTimeRadiusTileIndex),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);

        final controller = tester
            .widget<ListWheelScrollView>(find.byType(ListWheelScrollView))
            .controller! as FixedExtentScrollController;
        controller.jumpToItem(
          _TestConstants.selectedHabitualMemsTimeRadius -
              minHabitualMemsTimeRadius,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);

        final captured = verify(mockedPreferenceRepository.receive(captureAny))
            .captured
            .single as PreferenceEntity;
        expect(captured.key, habitualMemsTimeRadiusKey);
        expect(captured.value, _TestConstants.selectedHabitualMemsTimeRadius);

        expect(
          tester
              .widget<Text>(find
                  .byType(Text)
                  .at(_TestConstants.habitualMemsTimeRadiusValueIndex))
              .data,
          equals('${_TestConstants.selectedHabitualMemsTimeRadius}'),
        );
      });

      testWidgets('habitual mems lookback value.', (tester) async {
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);
        final habitualMemsLookbackValue = tester
            .widget<Text>(
                textWidgets.at(_TestConstants.habitualMemsLookbackValueIndex))
            .data;
        expect(
          habitualMemsLookbackValue,
          equals('$defaultHabitualMemsLookback'),
        );

        await tester.tap(
          find
              .byType(SettingsTile)
              .at(_TestConstants.habitualMemsLookbackTileIndex),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);

        final controller = tester
            .widget<ListWheelScrollView>(find.byType(ListWheelScrollView))
            .controller! as FixedExtentScrollController;
        controller.jumpToItem(
          _TestConstants.selectedHabitualMemsLookback -
              minHabitualMemsLookback,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);

        final captured = verify(mockedPreferenceRepository.receive(captureAny))
            .captured
            .single as PreferenceEntity;
        expect(captured.key, habitualMemsLookbackKey);
        expect(captured.value, _TestConstants.selectedHabitualMemsLookback);

        expect(
          tester
              .widget<Text>(find
                  .byType(Text)
                  .at(_TestConstants.habitualMemsLookbackValueIndex))
              .data,
          equals('${_TestConstants.selectedHabitualMemsLookback}'),
        );
      });
    });

    group('should delete', () {
      testWidgets('start of day value when cancelled.', (tester) async {
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);
        final startOfDayValue = tester
            .widget<Text>(textWidgets.at(_TestConstants.startOfDayValueIndex))
            .data;
        expect(startOfDayValue, equals('12:00 AM'));

        await tester.tap(find.byType(SettingsTile).first);
        await tester.pumpAndSettle();

        expect(find.byType(TimePickerDialog), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(TimePickerDialog), findsNothing);
      });

      testWidgets('notify after inactivity value when set to null.',
          (tester) async {
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);
        final notifyAfterInactivityValue = tester
            .widget<Text>(
                textWidgets.at(_TestConstants.notifyAfterInactivityValueIndex))
            .data;
        expect(notifyAfterInactivityValue, equals('1 h 0 m'));

        await tester.tap(find.byType(SettingsTile).at(1));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsNothing);
      });
    });
  });
}
