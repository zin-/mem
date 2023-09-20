import 'package:mem/repositories/conditions/conditions.dart';

class In extends Condition {
  final String _key;
  final Iterable _values;

  In(this._key, this._values);

  @override
  String where() => '$_key IN ( ${_values.join(', ')} )';

  @override
  List<Object?>? whereArgs() => null;

  @override
  String toString() => where();
}
