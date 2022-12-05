import 'types.dart';

abstract class Condition {
  final AttributeName _key;

  Condition(this._key);

  String whereString();

  dynamic whereArg();
}

typedef Conditions = Iterable<Condition>;

class Equals extends Condition {
  final dynamic _value;

  Equals(super.key, this._value);

  @override
  String whereString() => '$_key = ?';

  @override
  dynamic whereArg() => _value;

  @override
  String toString() => '$_key = $_value';
}
