import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/framework/repository/repository.dart';

abstract class KeyWithValueRepository<ENTITY extends KeyWithValue<KEY, dynamic>,
    KEY> extends RepositoryV2<ENTITY> {
  Future<void> receive(ENTITY entity);

  Future<void> discard(KEY key);
}

mixin DiscardAll<ENTITY extends KeyWithValue<KEY, dynamic>, KEY>
    on KeyWithValueRepository<ENTITY, KEY> {
  Future<void> discardAll();
}
