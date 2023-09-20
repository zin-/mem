import 'entity.dart';
import 'conditions/conditions.dart';

abstract class RepositoryV2<E extends EntityV2, Payload> {
  Future<Payload> receive(Payload payload);

  Future<List<Payload>> ship(Condition condition);

  Future<Payload> shipById(dynamic id);

  Future<Payload> replace(Payload payload);

  Future<Payload> archive(Payload payload);

  Future<Payload> unarchive(Payload payload);

  Future<List<Payload>> waste(Condition condition);

  Future<Payload> wasteById(dynamic id);
}
