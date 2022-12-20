import 'types.dart';

abstract class Condition {
  String whereString();

  dynamic whereArg();
}

typedef Conditions = Iterable<Condition>;

class Equals extends Condition {
  final AttributeName _key;
  final dynamic _value;

  Equals(this._key, this._value);

  @override
  String whereString() => '$_key = ?';

  @override
  dynamic whereArg() => _value;

  @override
  String toString() => '$_key = $_value';
}

class IsNull extends Condition {
  static const _operator = 'IS NULL';
  final AttributeName _key;

  IsNull(this._key);

  @override
  String whereString() {
    return '$_key $_operator';
  }

  @override
  whereArg() {
    return null;
  }

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
  whereArg() {
    return null;
  }

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
  String whereString() {
    return _conditions.map((e) => e.whereString()).join(_operator);
  }

  @override
  Iterable<Object> whereArg() {
    return _conditions.map((e) => e.whereArg()).whereType<Object>();
  }

  @override
  String toString() {
    return _conditions.map((e) => e.toString()).join(_operator);
  }
}
