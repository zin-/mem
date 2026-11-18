import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/line_chart_period.dart';
import 'package:mem/features/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/framework/date_and_time/period.dart';

import '../entity_factories.dart';

const _name = 'LineChartPeriod test';

// 今の期間。ページは置かず、この offset の1期間だけ見る
const _currentPeriodOffset = 0;

// このテストが置く mem。期間の中身は id を見ない
const _memId = 1;

// 時間。期間の内外は開始時刻で決まり、打点には正の長さがあれば足りる
const _actLength = Duration(hours: 1);

// 時。表示は 1h 2m 3s
const _elapsedHours = 1;

// 分。表示は 1h 2m 3s
const _elapsedMinutes = 2;

// 秒。表示は 1h 2m 3s
const _elapsedSeconds = 3;

// 未保存の id は 0。保存済みは 1 から振る
const _firstSavedActId = 1;

void main() {
  group(_name, () {
    testWidgets(
      'shows the period label, summary, and chart.',
      (tester) async {
        await _pumpPeriod(tester);

        expect(
          _visibleRangeLabel(_localizations(tester)),
          findsOneWidget,
        );
        expect(find.text('Min : '), findsOneWidget);
        expect(find.text('Max : '), findsOneWidget);
        expect(find.text('Avg : '), findsOneWidget);
        expect(find.byType(LineChartWrapper).hitTestable(), findsOneWidget);
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

        await _pumpPeriod(
          tester,
          acts: [
            FinishedAct(
              _memId,
              insideStart,
              insideStart.add(_actLength),
            ),
            FinishedAct(
              _memId,
              outsideStart,
              outsideStart.add(_actLength),
            ),
          ],
        );

        final spots = tester
            .widget<LineChart>(find.byType(LineChart).hitTestable())
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

    testWidgets(
      'shows elapsed time.',
      (tester) async {
        final start =
            Period.aWeek.toPeriod(DateAndTime.now(), defaultStartOfDay)!.start;

        await _pumpPeriod(
          tester,
          aggregationType: AggregationType.time,
          acts: [
            FinishedAct(
              _memId,
              start,
              // add は秒を捨てる
              DateAndTime(
                start.year,
                start.month,
                start.day,
                start.hour + _elapsedHours,
                _elapsedMinutes,
                _elapsedSeconds,
              ),
            ),
          ],
        );

        expect(
          find.text(
              '${_elapsedHours}h ${_elapsedMinutes}m ${_elapsedSeconds}s'),
          findsAtLeastNWidgets(1),
        );
      },
    );
  });
}

Future<void> _pumpPeriod(
  WidgetTester tester, {
  Period period = Period.aWeek,
  int offset = _currentPeriodOffset,
  AggregationType aggregationType = AggregationType.count,
  List<Act> acts = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        loadActListProvider(_memId, period, offset).overrideWith(
          (ref) => AsyncValue.data(acts),
        ),
        actListProvider(_memId).overrideWith(
          (ref) => acts
              .mapIndexed(
                (index, act) => savedActFromDomain(
                  act,
                  id: index + _firstSavedActId,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              )
              .toList(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LineChartPeriod(
            memId: _memId,
            period: period,
            offset: offset,
            aggregationType: aggregationType,
            startOfDay: defaultStartOfDay,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MaterialLocalizations _localizations(WidgetTester tester) =>
    MaterialLocalizations.of(
      tester.element(find.byType(LineChartPeriod)),
    );

String _rangeLabel(
  MaterialLocalizations localizations, {
  Period period = Period.aWeek,
  int offset = _currentPeriodOffset,
}) =>
    period
        .toPeriod(DateAndTime.now(), defaultStartOfDay, offset: offset)!
        .formatCompactRange(localizations);

Finder _visibleRangeLabel(
  MaterialLocalizations localizations, {
  Period period = Period.aWeek,
  int offset = _currentPeriodOffset,
}) =>
    find
        .text(_rangeLabel(localizations, period: period, offset: offset))
        .hitTestable();
