import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mems/list/filter.dart';
import 'package:mem/features/mems/list/filter_value.dart';
import 'package:mem/features/mems/list/states.dart';

void main() {
  testWidgets('each switch updates memListFilterStateProvider', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MemListFilter(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(memListFilterStateProvider), const MemListFilterValue());

    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(4));

    for (var i = 0; i < 4; i++) {
      await tester.tap(switches.at(i));
      await tester.pumpAndSettle();
    }

    expect(
      container.read(memListFilterStateProvider),
      const MemListFilterValue(
        showNotArchived: false,
        showArchived: true,
        showNotDone: false,
        showDone: true,
      ),
    );
  });
}
