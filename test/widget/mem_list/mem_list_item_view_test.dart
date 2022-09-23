import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/mem_list/mem_list_item_view.dart';

void main() {
  Logger(level: Level.verbose);

  Future pumpMemListItemView(WidgetTester widgetTester, int memId) async {
    await widgetTester.pumpWidget(
      ProviderScope(
        child: MemListItemView(memId),
      ),
    );
  }

  testWidgets('Show', (widgetTester) async {
    await pumpMemListItemView(widgetTester, 1);
    await widgetTester.pump();
  });
}
