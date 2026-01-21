import 'package:drift/drift.dart' as drift;
import 'package:mem/framework/repository/condition/conditions.dart';

class In extends Condition {
  final String _key;
  final Iterable _values;

  In(this._key, this._values);

  @override
  String where() => '$_key IN ( ${_values.join(', ')} )';

  @override
  List<Object?>? whereArgs() => null;

  @override
  drift.Expression<bool>? toDriftExpression(drift.TableInfo tableInfo) {
    final column = _getColumn(tableInfo, _key);
    if (column == null) return null;
    return _inExpression(column, _values);
  }

  @override
  String toString() => where();
}

drift.GeneratedColumn? _getColumn(drift.TableInfo tableInfo, String columnName) {
  try {
    final table = tableInfo as dynamic;
    final columns = table.$columns as List<drift.GeneratedColumn>;
    final column = columns.firstWhere(
      (col) {
        final actualName = _getColumnName(col);
        return actualName == columnName || actualName == _toSnakeCase(columnName);
      },
      orElse: () => throw StateError('Column not found: $columnName'),
    );
    return column;
  } catch (e) {
    return null;
  }
}

String _getColumnName(drift.GeneratedColumn column) {
  try {
    final col = column as dynamic;
    return col.actualColumnName as String? ?? col.name as String? ?? '';
  } catch (e) {
    return '';
  }
}

String _toSnakeCase(String camelCase) {
  return camelCase.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

drift.Expression<bool> _inExpression(
  drift.GeneratedColumn column,
  Iterable values,
) {
  if (column is drift.IntColumn) {
    return column.isIn(values.cast<int>().toList());
  } else if (column is drift.TextColumn) {
    return column.isIn(values.cast<String>().toList());
  } else if (column is drift.DateTimeColumn) {
    return column.isIn(values.cast<DateTime>().toList());
  } else {
    return column.isIn(values.cast<Object>().toList());
  }
}
