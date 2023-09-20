import 'package:mem/repositories/i/conditions.dart';

class In extends Condition {
  final String _key;
  final Iterable _values;

  In(this._key, this._values);

  @override
  String whereString() => '$_key IN ( ${_values.join(', ')} )';

  @override
  Iterable? whereArgs() => null;

  @override
  String toString() => whereString();
}
