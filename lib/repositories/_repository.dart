abstract class Repository<E extends Entity, Result> {
  Result receive(E entity);
}

abstract class Entity {}
