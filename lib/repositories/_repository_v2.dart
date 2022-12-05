import 'i/_entity_v2.dart';
import 'i/conditions.dart';

abstract class RepositoryV2<E extends EntityV2, Payload> {
  Future<Payload> receive(Payload payload);

  Future<List<Payload>> ship(Condition condition);

  // TODO: 必要になったら実装する
  // Future<List<Payload>> ship(Conditions conditions);

  Future<Payload> replace(Payload payload);

  Future<Payload> archive(Payload payload);

  Future<Payload> unarchive(Payload payload);

  Future<List<Payload>> waste(Conditions conditions);
}
