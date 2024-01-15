import 'package:mem/framework/repository/entity.dart';

abstract class KeyWithValue<Key, Value> extends Entity {
  final Key key;
  final Value value;

  KeyWithValue(this.key, this.value);

  @override
  String toString() => {
        "key": key,
        "value": value,
      }.toString();
}
