import 'package:mem/framework/database/converter.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';

abstract class Condition {
  String? where();

  List<Object?>? whereArgs();
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
  String toString() => '${_columnDefinition.name} < $_value';
}
