import 'package:mem/framework/repository/entity.dart';

abstract class KeyWithValue<Key, Value> extends EntityV2 {
  final Key key;
  final Value value;

  KeyWithValue(this.key, this.value);

  @override
  String toString() => {
        "key": key,
        "value": value,
      }.toString();
}

// FIXME IdWithValueの方が命名として適切なのでは？
mixin KeyWithValueV2<KEY, VALUE> on Entity {
  late final KEY key;
  late final VALUE value;
}
