import 'package:mem/repositories/i/conditions.dart';
import 'package:mem/repositories/i/types.dart';

class In extends Condition {
  final AttributeName _key;
  final Iterable _values;

  In(this._key, this._values);

  @override
  String whereString() => '$_key IN ${_values.toString()}';

  @override
  Iterable? whereArgs() => null;

  @override
  String toString() => whereString();
}
