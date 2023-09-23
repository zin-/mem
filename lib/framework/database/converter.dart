import 'package:mem/logger/log_service.dart';

import 'definition/column/boolean_column_definition.dart';
import 'definition/column/timestamp_column_definition.dart';
import 'definition/table_definition.dart';

class DatabaseConverter {
  Object? to(Object? value) => v(
        () => value is DateTime
            ? value.toIso8601String()
            : value is bool
                ? value
                    ? 1
                    : 0
                : value,
        value,
      );

  Map<String, Object?> from(
    Map<String, Object?> values,
    TableDefinition tableDefinition,
  ) =>
      v(
        () => values.map((key, value) {
          switch (tableDefinition.columnDefinitions
              .singleWhere((element) => element.name == key)
              .runtimeType) {
            case TimestampColumnDefinition:
              return MapEntry(
                  key, value == null ? null : DateTime.parse(value as String));
            case BooleanColumnDefinition:
              return MapEntry(key, value == null ? null : value == 1);
            default:
              return MapEntry(key, value);
          }
        }),
        [values, tableDefinition],
      );
}
