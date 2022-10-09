abstract class Repository<E extends Entity, Result> {
  Result receive(E entity);
}

abstract class Entity {
  Map<String, dynamic> toMap();

  @override
  String toString() => '$runtimeType: ${toMap().toString()}';
}
