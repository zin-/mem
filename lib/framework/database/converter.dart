import 'package:collection/collection.dart';

import 'definition/column/boolean_column_definition.dart';
import 'definition/column/timestamp_column_definition.dart';
import 'definition/table_definition.dart';

class DatabaseConverter {
  Object? to(Object? value) => value is DateTime
      ? value.toIso8601String()
      : value is bool
          ? value
              ? 1
              : 0
          : value;

  Map<String, Object?> from(
    Map<String, Object?> values,
    TableDefinition tableDefinition,
  ) =>
      values.map((key, value) {
        switch (tableDefinition.columnDefinitions
            .singleWhereOrNull((element) => element.name == key)
            .runtimeType) {
          case TimestampColumnDefinition:
            return MapEntry(
                key, value == null ? null : DateTime.parse(value as String));
          case BooleanColumnDefinition:
            return MapEntry(key, value == null ? null : value == 1);
          default:
            return MapEntry(key, value);
        }
      });
}
