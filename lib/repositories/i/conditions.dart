import 'package:mem/framework/database/definitions/column_definition.dart';

import 'types.dart';

abstract class Condition {
  String whereString();

  Iterable<dynamic>? whereArgs();
}

typedef Conditions = Iterable<Condition>;

class Equals extends Condition {
  final AttributeName _key;
  final dynamic _value;

  Equals(this._key, this._value);

  @override
  String whereString() => '$_key = ?';

  @override
  Iterable<dynamic> whereArgs() => [_value];

  @override
  String toString() => '$_key = $_value';
}

class IsNull extends Condition {
  static const _operator = 'IS NULL';
  final AttributeName _key;

  IsNull(this._key);

  @override
  String whereString() => '$_key $_operator';

  @override
  Iterable<dynamic>? whereArgs() => null;

  @override
  String toString() {
    return '$_key $_operator';
  }
}

class IsNotNull extends Condition {
  static const _operator = 'IS NOT NULL';
  final AttributeName _key;

  IsNotNull(this._key);

  @override
  String whereString() {
    return '$_key $_operator';
  }

  @override
  Iterable<dynamic>? whereArgs() => null;

  @override
  String toString() {
    return '$_key $_operator';
  }
}

class And extends Condition {
  static const _operator = ' AND ';

  final Conditions _conditions;

  And(this._conditions) : super();

  @override
  String whereString() =>
      _conditions.map((e) => '( ${e.whereString()} )').join(_operator);

  @override
  Iterable<dynamic> whereArgs() =>
      _conditions.map((e) => e.whereArgs()).expand((element) => element ?? []);

  @override
  String toString() => _conditions.map((e) => e.toString()).join(_operator);
}

class GraterThanOrEqual extends Condition {
  final ColumnDefinition _columnDefinition;
  final dynamic _value;

  GraterThanOrEqual(this._columnDefinition, this._value);

  @override
  Iterable? whereArgs() => [_columnDefinition.toTuple(_value)];

  @override
  String whereString() => '? <= ${_columnDefinition.name}';

  @override
  String toString() => '$_value <= ${_columnDefinition.name}';
}

class LessThan extends Condition {
  final ColumnDefinition _columnDefinition;
  final dynamic _value;

  LessThan(this._columnDefinition, this._value);

  @override
  Iterable? whereArgs() => [_columnDefinition.toTuple(_value)];

  @override
  String whereString() => '${_columnDefinition.name} < ?';

  @override
  String toString() => '${_columnDefinition.name} < $_value';
}
