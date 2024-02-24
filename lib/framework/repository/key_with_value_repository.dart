import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/framework/repository/repository.dart';

abstract class KeyWithValueRepository<E extends KeyWithValue<Key, dynamic>, Key>
    extends Repository<E>
    with Receiver<E, bool>, _DiscarderByKey<E, Key, bool> {}

mixin _DiscarderByKey<E extends KeyWithValue<Key, dynamic>, Key, Result>
    on Repository<E> {
  Future<Result> discard(Key key);
}
