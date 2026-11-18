import 'package:collection/collection.dart';
import '../entity_factories.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/line_chart_page.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/framework/date_and_time/period.dart';
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
import 'package:mem/values/dimens.dart';

const _name = 'ActLineChartPage test';

// px/秒。ページ送りの速度閾値より大きいので、離したページの隣へスナップする
const _flingSpeed = 1000.0;

// px。1枚の画面でも2枚の画面でも、1ページより短い。超えると2ページ進む
const _pageFlingDistance = 300.0;

// 論理px。既定のテスト画面と同じ幅。高さだけを変える
const _screenWidth = 800.0;

// physicalSize を論理pxとして使う
const _devicePixelRatio = 1.0;

// 論理px。画面高さを1期間の最大高さと同じにすると、AppBar と本文の余白を引いた本文はそれ以下。
// 期間は1枚。その1ページはフリック距離より高い
const _oneSlotScreen = Size(_screenWidth, lineChartPeriodMaxHeight);

// 論理px。AppBar と本文の余白を引いた本文が最大高さを超え、その2倍以下。
// 週は2枚で、1枚はフリック距離より高い。Period.all は上限が無ければこの本文いっぱいまで伸びる
const _tallScreenHeight = 800.0;
const _tallScreen = Size(_screenWidth, _tallScreenHeight);

// Y が負だと指は上へ動く。上へ払うと過去の期間へ進む
const _towardPast = Offset(0, -_pageFlingDistance);

// Y が正だと指は下へ動く。下へ払うと現在の期間へ戻る
const _towardPresent = Offset(0, _pageFlingDistance);

// 今の期間。PageView のページ 0
const _currentPeriodOffset = 0;

// 1期間過去。PageView のページ 1
const _previousPeriodOffset = -1;

// 2期間過去。2枚見えるときは、払うまで画面の外
const _twoPeriodsAgoOffset = _previousPeriodOffset - 1;

// 1期間未来。ページ 0 からは表示されない
const _futurePeriodOffset = 1;

// 過去ページの隣（さらに1期間過去）まで含む。未 stub の offset は実 DB を叩く
const _stubbedPeriodOffsets = [
  _currentPeriodOffset,
  _previousPeriodOffset,
  _twoPeriodsAgoOffset,
];

void main() {
  group(_name, () {
    testWidgets(
      'should display basic structure.',
      (tester) async {
        final memId = 1;
        final memName = 'memName - $_name';

        await _pumpPage(tester, memId: memId, memName: memName);

        expect(
          find.text("$memName : ${AggregationType.count.name}"),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.chevron_left), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );

    testWidgets(
      'flings to the previous period and back, and does not enter the future.',
      (tester) async {
        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - period nav',
        );

        final localizations = _localizations(tester);

        expect(_visibleRangeLabel(localizations), findsOneWidget);

        await _flingVisibleChart(tester, _towardPast);

        expect(
          _visibleRangeLabel(localizations, offset: _previousPeriodOffset),
          findsOneWidget,
        );

        await _flingVisibleChart(tester, _towardPresent);

        expect(_visibleRangeLabel(localizations), findsOneWidget);

        await _flingVisibleChart(tester, _towardPresent);

        expect(_visibleRangeLabel(localizations), findsOneWidget);
        expect(
          find.text(
            _rangeLabel(localizations, offset: _futurePeriodOffset),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'returns to the current range when the period type changes.',
      (tester) async {
        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - period reset',
        );

        final localizations = _localizations(tester);

        await _flingVisibleChart(tester, _towardPast);

        expect(
          _visibleRangeLabel(localizations, offset: _previousPeriodOffset),
          findsOneWidget,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(Period.aMonth.name));
        await tester.pumpAndSettle();

        expect(
          _visibleRangeLabel(localizations, period: Period.aMonth),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'selects time and shows it in the title.',
      (tester) async {
        final memName = 'memName - time';

        await _pumpPage(
          tester,
          memId: 1,
          memName: memName,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(AggregationType.time.name));
        await tester.pumpAndSettle();

        expect(
          find.text('$memName : ${AggregationType.time.name}'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'has no PageView for Period.all.',
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

        expect(find.byType(PageView), findsNothing);
        expect(find.byType(LineChartWrapper), findsOneWidget);
      },
    );

    testWidgets(
      'shows the current and previous periods when the body is taller than one period.',
      (tester) async {
        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - two periods',
          screen: _tallScreen,
        );

        final localizations = _localizations(tester);

        expect(_visibleRangeLabel(localizations), findsOneWidget);
        expect(
          _visibleRangeLabel(localizations, offset: _previousPeriodOffset),
          findsOneWidget,
        );
        expect(
          _visibleRangeLabel(
            localizations,
            offset: _twoPeriodsAgoOffset,
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'shows only the current period when the body fits in one period.',
      (tester) async {
        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - one period',
          screen: _oneSlotScreen,
        );

        final localizations = _localizations(tester);

        expect(_visibleRangeLabel(localizations), findsOneWidget);
        expect(
          _visibleRangeLabel(localizations, offset: _previousPeriodOffset),
          findsNothing,
        );
      },
    );

    testWidgets(
      'advances one period when two periods are visible.',
      (tester) async {
        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - two period fling',
          screen: _tallScreen,
        );

        final localizations = _localizations(tester);

        await _flingVisibleChart(tester, _towardPast);

        expect(_visibleRangeLabel(localizations), findsNothing);
        expect(
          _visibleRangeLabel(localizations, offset: _previousPeriodOffset),
          findsOneWidget,
        );
        expect(
          _visibleRangeLabel(
            localizations,
            offset: _twoPeriodsAgoOffset,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'keeps Period.all within one period height on a tall screen.',
      (tester) async {
        await _pumpPage(
          tester,
          memId: 1,
          memName: 'memName - period all height',
          screen: _tallScreen,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(Period.all.name));
        await tester.pumpAndSettle();

        expect(
          _periodBlockHeight(tester),
          lessThanOrEqualTo(lineChartPeriodMaxHeight),
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
  Size screen = _oneSlotScreen,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = _devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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

Future<void> _flingVisibleChart(WidgetTester tester, Offset offset) async {
  await tester.fling(
    find.byType(LineChartWrapper).hitTestable().first,
    offset,
    _flingSpeed,
  );
  await tester.pumpAndSettle();
}

double _periodBlockHeight(WidgetTester tester) {
  final block = find.ancestor(
    of: find.byType(LineChartWrapper),
    matching: find.byWidgetPredicate(
      (widget) => widget is Flex && widget.direction == Axis.vertical,
    ),
  );
  expect(block, findsOneWidget);
  return tester.getSize(block).height;
}

List<Override> _overrides(int memId, String memName, List<Act> acts) => [
      for (final period in Period.values)
        for (final offset in _stubbedPeriodOffsets)
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
          target: null,
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
