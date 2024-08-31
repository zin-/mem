import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/framework/repository/repository.dart';

abstract class KeyWithValueRepository<ENTITY extends KeyWithValue<KEY, dynamic>,
    KEY> extends Repository<ENTITY> {
  Future<void> receive(ENTITY entity) => throw UnimplementedError();

  Future<void> discard(KEY key) => throw UnimplementedError();

  Future<void> discardAll() => throw UnimplementedError();
}
