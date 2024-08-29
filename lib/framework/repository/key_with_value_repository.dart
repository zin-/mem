import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/framework/repository/repository.dart';

abstract class KeyWithValueRepository<E extends KeyWithValue<Key, dynamic>, Key>
    extends RepositoryV2<E>
    with Receiver<E, bool>, DiscarderByKey<E, Key, bool> {}

mixin DiscarderByKey<E extends KeyWithValue<Key, dynamic>, Key, Result>
    on RepositoryV2<E> {
  Future<Result> discard(Key key);
}

abstract class KeyWithValueRepositoryV2<
    ENTITY extends KeyWithValueV2<KEY, dynamic>,
    KEY> extends Repository<ENTITY> {
  Future<void> receive(ENTITY entity);

  Future<void> discard(int key);

  Future<void> discardAll();
}
