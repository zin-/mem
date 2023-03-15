@Deprecated('use instead RepositoryV2')
abstract class Repository<E extends Entity, Result> {
  Result receive(E entity);
}

@Deprecated('use instead EntityV2')
abstract class Entity {}
