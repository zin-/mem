import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_items/mem_items_view.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';

void main() {
  testWidgets('shows the saved memo when the empty draft is replaced',
      (tester) async {
    const memId = 1;
    final notifier = ListValueStateNotifier<MemItemEntityV1>([
      MemItemEntityV1(MemItem(memId, MemItemType.memo, '')),
    ]);
    final saved = SavedMemItemEntityV1.fromEntityV2(
      MemItemEntity(
        memId,
        MemItemType.memo,
        'loaded',
        10,
        DateTime(2024, 6, 1),
        DateTime(2024, 6, 1),
        null,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memItemsByMemIdProvider(memId).overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MemItemsFormFields(memId)),
        ),
      ),
    );

    expect(
      tester.widget<TextFormField>(find.byKey(keyMemMemo)).initialValue,
      '',
    );

    notifier.updatedBy([saved]);
    await tester.pump();

    expect(find.text('loaded'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('mem-memo-10')))
          .initialValue,
      'loaded',
    );
  });
}
