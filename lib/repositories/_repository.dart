// TODO @Deprecated('use instead RepositoryV2')
abstract class Repository<E extends Entity, Result> {
  Result receive(E entity);
}

// TODO @Deprecated('use instead EntityV2')
abstract class Entity {}
