import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/line_chart_page.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              loadActListProvider(memId, Period.aWeek).overrideWith(
                (ref) => AsyncValue.data(acts),
              ),
              memByMemIdProvider(memId).overrideWith(
                (ref) => ValueStateNotifier(MemEntity(
                  memId,
                  memName,
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
                    .mapIndexed((index, act) => SavedActEntityV1({
                          defPkId.name: index + 1,
                          defFkActsMemId.name: act.memId,
                          defColActsStart.name: act.period?.start,
                          defColActsStartIsAllDay.name:
                              act.period?.start?.isAllDay,
                          defColActsEnd.name: act.period?.end,
                          defColActsEndIsAllDay.name: act.period?.end?.isAllDay,
                          defColActsPausedAt.name: act.pausedAt,
                          defColCreatedAt.name: DateTime.now(),
                          defColUpdatedAt.name: DateTime.now(),
                          defColArchivedAt.name: null,
                        }))
                    .toList(),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ActLineChartPage(memId: memId),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text("$memName : ${AggregationType.count.name}"),
          findsOneWidget,
        );
        expect(find.text('Min : '), findsOneWidget);
        expect(find.text('Max : '), findsOneWidget);
        expect(find.text('Avg : '), findsOneWidget);
        expect(find.byType(LineChartWrapper), findsOneWidget);
      },
    );
  });
}

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
