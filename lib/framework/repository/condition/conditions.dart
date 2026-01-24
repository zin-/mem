import 'package:drift/drift.dart' as drift;
import 'package:mem/framework/database/converter.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';

abstract class Condition {
  String? where();

  List<Object?>? whereArgs();

  drift.Expression<bool>? toDriftExpression(drift.TableInfo tableInfo);
}

class Equals extends Condition {
  final ColumnDefinition _columnDefinition;
  final dynamic _value;

  Equals(this._columnDefinition, this._value);

  @override
  String? where() => "${_columnDefinition.name} = ?";

  @override
  List<Object?>? whereArgs() => [DatabaseConverter().to(_value)];

  @override
  drift.Expression<bool>? toDriftExpression(drift.TableInfo tableInfo) {
    final column = _getColumn(tableInfo, _columnDefinition.name);
    if (column == null) return null;
    final convertedValue = DatabaseConverter().to(_value);
    return _equalsExpression(column, convertedValue);
  }

  @override
  String toString() => "${_columnDefinition.name} = $_value";
}

class IsNull extends Condition {
  static const _operator = 'IS NULL';

  // TODO ColumnDefinitionに変更する
  final String _key;

  IsNull(this._key);

  @override
  String where() => '$_key $_operator';

  @override
  List<Object?>? whereArgs() => null;

  @override
  drift.Expression<bool>? toDriftExpression(drift.TableInfo tableInfo) {
    final column = _getColumn(tableInfo, _key);
    if (column == null) return null;
    return _isNullExpression(column);
  }

  @override
  String toString() {
    return '$_key $_operator';
  }
}

class IsNotNull extends Condition {
  static const _operator = 'IS NOT NULL';

  // TODO ColumnDefinitionに変更する
  final String _key;

  IsNotNull(this._key);

  @override
  String where() {
    return '$_key $_operator';
  }

  @override
  List<Object?>? whereArgs() => null;

  @override
  drift.Expression<bool>? toDriftExpression(drift.TableInfo tableInfo) {
    final column = _getColumn(tableInfo, _key);
    if (column == null) return null;
    return _isNotNullExpression(column);
  }

  @override
  String toString() {
    return '$_key $_operator';
  }
}

class And extends Condition {
  static const _operator = ' AND ';

  final Iterable<Condition> _conditions;

  And(this._conditions) : super();

  @override
  String? where() => _conditions.isEmpty
      ? null
      : _conditions.map((e) => '( ${e.where()} )').join(_operator);

  @override
  List<Object?>? whereArgs() => _conditions.isEmpty
      ? null
      : _conditions
          .map((e) => e.whereArgs())
          .expand((element) => element ?? [])
          .toList();

  @override
  drift.Expression<bool>? toDriftExpression(drift.TableInfo tableInfo) {
    if (_conditions.isEmpty) return null;
    final expressions = _conditions
        .map((e) => e.toDriftExpression(tableInfo))
        .whereType<drift.Expression<bool>>()
        .toList();
    if (expressions.isEmpty) return null;
    return expressions.reduce((a, b) => a & b);
  }

  @override
  String toString() => _conditions.map((e) => e.toString()).join(_operator);
}

class Or extends Condition {
  static const _operator = ' OR ';

  final Iterable<Condition> _conditions;

  Or(this._conditions) : super();

  @override
  String? where() => _conditions.isEmpty
      ? null
      : _conditions.map((e) => '( ${e.where()} )').join(_operator);

  @override
  List<Object?>? whereArgs() => _conditions.isEmpty
      ? null
      : _conditions
          .map((e) => e.whereArgs())
          .expand((element) => element ?? [])
          .toList();

  @override
  drift.Expression<bool>? toDriftExpression(drift.TableInfo tableInfo) {
    if (_conditions.isEmpty) return null;
    final expressions = _conditions
        .map((e) => e.toDriftExpression(tableInfo))
        .whereType<drift.Expression<bool>>()
        .toList();
    if (expressions.isEmpty) return null;
    return expressions.reduce((a, b) => a | b);
  }

  @override
  String toString() => _conditions.map((e) => e.toString()).join(_operator);
}

class GraterThanOrEqual extends Condition {
  final ColumnDefinition _columnDefinition;
  final Object? _value;

  GraterThanOrEqual(this._columnDefinition, this._value);

  @override
  String where() => '? <= ${_columnDefinition.name}';

  @override
  List<Object?>? whereArgs() => [_value];

  @override
  drift.Expression<bool>? toDriftExpression(drift.TableInfo tableInfo) {
    final column = _getColumn(tableInfo, _columnDefinition.name);
    if (column == null) return null;
    return _greaterThanOrEqualExpression(column, _value);
  }

  @override
  String toString() => '$_value <= ${_columnDefinition.name}';
}

class LessThan extends Condition {
  final ColumnDefinition _columnDefinition;
  final dynamic _value;

  LessThan(this._columnDefinition, this._value);

  @override
  String where() => '${_columnDefinition.name} < ?';

  @override
  List<Object?>? whereArgs() => [_value];

  @override
  drift.Expression<bool>? toDriftExpression(drift.TableInfo tableInfo) {
    final column = _getColumn(tableInfo, _columnDefinition.name);
    if (column == null) return null;
    return _lessThanExpression(column, _value);
  }

  @override
  String toString() => '${_columnDefinition.name} < $_value';
}

const _tableDefToDriftColumn = {
  'mems_id': 'mem_id',
  'source_mems_id': 'source_mem_id',
  'target_mems_id': 'target_mem_id',
};

drift.GeneratedColumn? _getColumn(
    drift.TableInfo tableInfo, String columnName) {
  try {
    final table = tableInfo as dynamic;
    final columns = table.$columns as List<drift.GeneratedColumn>;
    final column = columns.firstWhere(
      (col) {
        final actualName = _getColumnName(col);
        return actualName == columnName ||
            actualName == _toSnakeCase(columnName) ||
            ( _tableDefToDriftColumn[columnName] != null &&
                actualName == _tableDefToDriftColumn[columnName]);
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
    return col.name as String? ?? '';
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

drift.Expression<bool> _equalsExpression(
  drift.GeneratedColumn column,
  dynamic value,
) {
  if (column is drift.IntColumn) {
    return column.equals(value as int);
  } else if (column is drift.TextColumn) {
    return column.equals(value as String);
  } else if (column is drift.DateTimeColumn) {
    return column.equals(value as DateTime);
  } else if (column is drift.BoolColumn) {
    return column.equals(value as bool);
  } else {
    return column.equals(value);
  }
}

drift.Expression<bool> _isNullExpression(drift.GeneratedColumn column) {
  return column.isNull();
}

drift.Expression<bool> _isNotNullExpression(drift.GeneratedColumn column) {
  return column.isNotNull();
}

drift.Expression<bool> _greaterThanOrEqualExpression(
  drift.GeneratedColumn column,
  dynamic value,
) {
  final col = column as dynamic;
  if (column is drift.IntColumn) {
    return (col >= (value as int)) as drift.Expression<bool>;
  } else if (column is drift.DateTimeColumn) {
    return (col >= (value as DateTime)) as drift.Expression<bool>;
  } else {
    return (col >= value) as drift.Expression<bool>;
  }
}

drift.Expression<bool> _lessThanExpression(
  drift.GeneratedColumn column,
  dynamic value,
) {
  final col = column as dynamic;
  if (column is drift.IntColumn) {
    return (col < (value as int)) as drift.Expression<bool>;
  } else if (column is drift.DateTimeColumn) {
    return (col < (value as DateTime)) as drift.Expression<bool>;
  } else {
    return (col < value) as drift.Expression<bool>;
  }
}
