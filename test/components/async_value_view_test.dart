import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';

import '../helpers.dart';

void main() {
  testWidgets(
    'throw',
    (widgetTester) async {
      LogService.initialize(Level.verbose);
      const thrown = 'test value - AsyncValue is not future: throw';

      await widgetTester.pumpWidget(
        buildTestAppWithProvider(
          AsyncValueView(
            FutureProvider((ref) => throw thrown),
            (String data) => Text(data),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect((widgetTester.widget(find.byType(Text)) as Text).data, thrown);
    },
  );
}
