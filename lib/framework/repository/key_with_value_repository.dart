import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/framework/repository/repository.dart';

abstract class KeyWithValueRepository<Entity extends KeyWithValue<Key, dynamic>,
        Key> extends ExRepository<Entity>
    with Receiver<Entity, bool>, _DiscarderByKey<Entity, Key, bool> {}

mixin _DiscarderByKey<Entity extends KeyWithValue<Key, dynamic>, Key, Result>
    on ExRepository<Entity> {
  Future<Result> discard(Key key);
}
