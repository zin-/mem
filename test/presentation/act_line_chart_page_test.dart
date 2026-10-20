import 'package:collection/collection.dart';
import '../entity_factories.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/line_chart_page.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/features/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/framework/view/value_state_notifier.dart';

const _name = 'ActLineChartPage test';

void main() {
  group(_name, () {
    testWidgets(
      'should display basic structure.',
      (tester) async {
        final memId = 1;
        final memName = 'memName - $_name';
        final acts = [
          FinishedAct(1, DateAndTime.from(DateTime(2025, 9, 25)),
              DateAndTime.from(DateTime(2025, 9, 25, 1))),
          FinishedAct(1, DateAndTime.from(DateTime(2025, 9, 26)),
              DateAndTime.from(DateTime(2025, 9, 26, 1))),
          FinishedAct(1, DateAndTime.from(DateTime(2025, 9, 27)),
              DateAndTime.from(DateTime(2025, 9, 27, 1))),
        ];

        await _pumpPage(tester, memId: memId, memName: memName, acts: acts);

        expect(
          find.text("$memName : ${AggregationType.count.name}"),
          findsOneWidget,
        );
        expect(find.text('Min : '), findsOneWidget);
        expect(find.text('Max : '), findsOneWidget);
        expect(find.text('Avg : '), findsOneWidget);
        expect(find.byType(LineChartWrapper), findsOneWidget);
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );

    testWidgets(
      'shows period range and navigates previous/next.',
      (tester) async {
        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - period nav',
        );

        final localizations = _localizations(tester);
        final nextButton = find.widgetWithIcon(IconButton, Icons.chevron_right);
        final previousButton =
            find.widgetWithIcon(IconButton, Icons.chevron_left);

        expect(find.text(_rangeLabel(localizations)), findsOneWidget);
        expect(tester.widget<IconButton>(nextButton).onPressed, isNull);

        await tester.tap(previousButton);
        await tester.pumpAndSettle();

        expect(
          find.text(_rangeLabel(localizations, offset: -1)),
          findsOneWidget,
        );
        expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);

        await tester.tap(nextButton);
        await tester.pumpAndSettle();

        expect(find.text(_rangeLabel(localizations)), findsOneWidget);
        expect(tester.widget<IconButton>(nextButton).onPressed, isNull);
      },
    );

    testWidgets(
      'resets offset when period type changes.',
      (tester) async {
        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - period reset',
        );

        final localizations = _localizations(tester);

        await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(Period.aMonth.name));
        await tester.pumpAndSettle();

        expect(
          find.text(_rangeLabel(localizations, period: Period.aMonth)),
          findsOneWidget,
        );
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_right),
              )
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets(
      'hides navigation for Period.all.',
      (tester) async {
        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - period all',
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(Period.all.name));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_left), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );

    testWidgets(
      'plots acts inside the period and drops the rest',
      (tester) async {
        final period = Period.aWeek.toPeriod(
          DateAndTime.now(),
          defaultStartOfDay,
        )!;
        final insideStart = period.start;
        final outsideStart = period.end;

        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - period filter',
          acts: [
            FinishedAct(
              1,
              insideStart,
              insideStart.add(const Duration(hours: 1)),
            ),
            FinishedAct(
              1,
              outsideStart,
              outsideStart.add(const Duration(hours: 1)),
            ),
          ],
        );

        final spots = tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData
            .last
            .spots
            .where((spot) => spot.y > 0);

        expect(spots, hasLength(1));
        expect(
          spots.single.x,
          DateAndTime(insideStart.year, insideStart.month, insideStart.day)
              .millisecondsSinceEpoch
              .toDouble(),
        );
      },
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required int memId,
  required String memName,
  List<Act> acts = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(memId, memName, acts),
      child: MaterialApp(
        home: Scaffold(
          body: ActLineChartPage(memId: memId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MaterialLocalizations _localizations(WidgetTester tester) =>
    MaterialLocalizations.of(
      tester.element(find.byType(ActLineChartPage)),
    );

String _rangeLabel(
  MaterialLocalizations localizations, {
  Period period = Period.aWeek,
  int offset = 0,
}) =>
    period
        .toPeriod(DateAndTime.now(), defaultStartOfDay, offset: offset)!
        .formatCompactRange(localizations);

List<Override> _overrides(int memId, String memName, List<Act> acts) => [
      for (final period in Period.values)
        for (final offset in const [0, -1])
          loadActListProvider(memId, period, offset).overrideWith(
            (ref) => AsyncValue.data(acts),
          ),
      memByMemIdProvider(memId).overrideWith(
        (ref) => ValueStateNotifier(MemEntity(
          memId,
          memName,
          null,
          null,
          null,
          DateTime.now(),
          DateTime.now(),
          null,
        )),
      ),
      preferenceProvider(startOfDayKey).overrideWith(
        () => _FakePreference(),
      ),
      actListProvider(memId).overrideWith(
        (ref) => acts
            .mapIndexed(
              (index, act) => savedActFromDomain(
                act,
                id: index + 1,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .toList(),
      ),
    ];

class _FakePreference<T> extends Preference<T> {
  T? _value;

  @override
  T build(PreferenceKey<T> key) {
    _value ??= defaultPreferences[key] as T;
    return _value as T;
  }

  @override
  Future<void> replace(T updating) async {
    _value = updating;
    state = updating;
  }

  @override
  Future<void> remove() async {
    _value = defaultPreferences[key] as T;
    state = _value as T;
  }
}
