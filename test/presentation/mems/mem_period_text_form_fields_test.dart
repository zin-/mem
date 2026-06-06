import '../../entity_factories.dart';
import '../../helpers.mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/log.dart';
import 'package:mem/features/logger/log_repository.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem_period.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/date_and_time/time_of_day_view.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mockito/mockito.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<SavedMemEntityV1> _initial;

  _FakeMemEntities(this._initial);

  @override
  Iterable<SavedMemEntityV1> build() => _initial;
}

Widget _buildTestApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

Future<void> pickTimeInDialog(
  WidgetTester tester,
  TimeOfDay timeOfDay,
) async {
  await tester.tap(find.byIcon(Icons.access_time_outlined).first);
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();

  final inputs = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextFormField),
  );
  final hour12 = timeOfDay.hour % 12 == 0 ? 12 : timeOfDay.hour % 12;
  await tester.enterText(inputs.at(0), '$hour12');
  await tester.enterText(inputs.at(1), '${timeOfDay.minute}');
  await tester.tap(find.text(timeOfDay.hour >= 12 ? 'PM' : 'AM'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

String startTimeFieldDisplayText(WidgetTester tester) {
  final timeFields = find.byType(TimeOfDayTextFormField);
  return tester
      .widget<EditableText>(
        find.descendant(
          of: timeFields.first,
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

void main() {
  final mockedLoggerWrapper = MockLoggerWrapper();
  final mockedSentryWrapper = MockSentryWrapper();

  LogRepository(
    mockedLoggerWrapper,
    mockedSentryWrapper,
  );

  LogService(level: Level.info);

  setUp(() {
    reset(mockedLoggerWrapper);
    reset(mockedSentryWrapper);

    when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);
    when(mockedSentryWrapper.captureException(any, any))
        .thenAnswer((_) => Future.value('test'));
  });

  group('MemPeriodTextFormFields', () {
    testWidgets(
      ': time pick updates editingMemByMemIdProvider period.',
      (tester) async {
        const memId = 1;
        final mem = savedMem(
          id: memId,
          name: 'Test mem',
          notifyOn: DateTime(2024, 6, 1),
          notifyAt: DateTime(2024, 6, 1, 10, 0),
          endOn: DateTime(2024, 6, 2),
        );

        late ProviderContainer container;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container = ProviderContainer(
              overrides: [
                memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem])),
              ],
            ),
            child: _buildTestApp(const MemPeriodTextFormFields(memId)),
          ),
        );
        addTearDown(container.dispose);

        await tester.pumpAndSettle();

        const pickedTime = TimeOfDay(hour: 14, minute: 30);
        await pickTimeInDialog(tester, pickedTime);

        final editingMem = container.read(editingMemByMemIdProvider(memId));

        expect(editingMem.value.period?.start?.hour, pickedTime.hour);
        expect(editingMem.value.period?.start?.minute, pickedTime.minute);
        expect(
          startTimeFieldDisplayText(tester),
          pickedTime.format(tester.element(find.byType(TimeOfDayTextFormField).first)),
        );
      },
    );

    testWidgets(
      ': time pick after provider autoDispose reports StateError to Sentry.',
      (tester) async {
        const memId = 1;
        final mem = savedMem(
          id: memId,
          name: 'Test mem',
          notifyOn: DateTime(2024, 6, 1),
          notifyAt: DateTime(2024, 6, 1, 10, 0),
          endOn: DateTime(2024, 6, 2),
        );

        final container = ProviderContainer(
          overrides: [
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem])),
          ],
        );
        addTearDown(container.dispose);

        final hostKey = GlobalKey<_MemPeriodHostState>();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _MemPeriodHost(key: hostKey, memId: memId),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.access_time_outlined).first);
        await tester.pumpAndSettle();

        expect(find.byType(TimePickerDialog), findsOneWidget);

        hostKey.currentState!.hidePeriodFields();
        await tester.pumpAndSettle();

        expect(find.byType(MemPeriodTextFormFields), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.pump();

        final captured = verify(
          mockedSentryWrapper.captureException(captureAny, captureAny),
        ).captured;

        expect(captured, isNotEmpty);
        expect(captured.first, isA<StateError>());
        expect(
          (captured.first as StateError).message,
          contains('unmounted'),
        );
      },
    );

    testWidgets(
      ': time pick after ProviderContainer dispose reports Riverpod StateError to Sentry.',
      (tester) async {
        const memId = 1;
        final mem = savedMem(
          id: memId,
          name: 'Test mem',
          notifyOn: DateTime(2024, 6, 1),
          notifyAt: DateTime(2024, 6, 1, 10, 0),
          endOn: DateTime(2024, 6, 2),
        );

        final container = ProviderContainer(
          overrides: [
            memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem])),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _buildTestApp(const MemPeriodTextFormFields(memId)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.access_time_outlined).first);
        await tester.pumpAndSettle();

        container.dispose();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.pump();

        final captured = verify(
          mockedSentryWrapper.captureException(captureAny, captureAny),
        ).captured;

        expect(captured, isNotEmpty);
        expect(captured.first, isA<StateError>());
        expect(
          (captured.first as StateError).message,
          'Tried to read a provider from a ProviderContainer that was already disposed',
        );
      },
    );
  });

  group('ValueStateNotifier.updatedBy after dispose', () {
    test(': throws StateError matching Sentry capture pattern.', () {
      final notifier = ValueStateNotifier(
        MemEntityV1(Mem(null, '', null, null)),
      );
      notifier.dispose();

      expect(
        () => notifier.updatedBy(MemEntityV1(Mem(null, 'x', null, null))),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Tried to use'),
              contains('after `dispose` was called'),
            ),
          ),
        ),
      );
    });
  });
}

class _MemPeriodHost extends StatefulWidget {
  const _MemPeriodHost({required this.memId, super.key});

  final int memId;

  @override
  State<_MemPeriodHost> createState() => _MemPeriodHostState();
}

class _MemPeriodHostState extends State<_MemPeriodHost> {
  var _showPeriodFields = true;

  void hidePeriodFields() => setState(() => _showPeriodFields = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _showPeriodFields
            ? MemPeriodTextFormFields(widget.memId)
            : const SizedBox.shrink(),
      ),
    );
  }
}
