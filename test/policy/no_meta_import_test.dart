import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ must not import package:meta', () {
    final violations = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      if (content.contains("import 'package:meta/") ||
          content.contains('import "package:meta/')) {
        violations.add(entity.path);
      }
    }
    expect(violations, isEmpty, reason: 'Do not import package:meta in lib/');
  });
}
