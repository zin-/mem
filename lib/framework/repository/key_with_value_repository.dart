import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/framework/repository/repository.dart';

abstract class KeyWithValueRepositoryV2<
    ENTITY extends KeyWithValue<KEY, dynamic>,
    KEY> extends Repository<ENTITY> {
  Future<void> receive(ENTITY entity);

  Future<void> discard(KEY key);

  Future<void> discardAll();
}
