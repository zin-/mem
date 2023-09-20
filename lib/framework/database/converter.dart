import 'package:mem/logger/log_service.dart';

import 'definition/column/boolean_column_definition.dart';
import 'definition/column/timestamp_column_definition.dart';
import 'definition/table_definition.dart';

class DatabaseConverter {
  Map<String, Object?> to(
    Map<String, Object?> values,
    TableDefinitionV2 tableDefinition,
  ) =>
      v(
        () => values.map((key, value) {
          switch (tableDefinition.columnDefinitions
              .singleWhere((element) => element.name == key)
              .runtimeType) {
            case TimestampColumnDefinition:
              return MapEntry(key, (value as DateTime?)?.toIso8601String());
            case BooleanColumnDefinition:
              return MapEntry(
                  key,
                  value == null
                      ? null
                      : value == true
                          ? 1
                          : 0);
            default:
              return MapEntry(key, value);
          }
        }),
        [values, tableDefinition],
      );

  Map<String, Object?> from(
    Map<String, Object?> values,
    TableDefinitionV2 tableDefinition,
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
