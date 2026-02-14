import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class Dummy {
  Dummy() {
    throw UnimplementedError();
  }
}

class DummyEntity with EntityV1<Dummy> {
  DummyEntity() {
    throw UnimplementedError();
  }

  @override
  Map<String, Object?> get toMap => throw UnimplementedError();

  @override
  EntityV1<Dummy> updatedWith(Dummy Function(Dummy v) update) =>
      throw UnimplementedError();
}

class SavedDummyEntity extends DummyEntity
    with DatabaseTupleEntityV1<int, Dummy> {
  SavedDummyEntity() : super() {
    throw UnimplementedError();
  }

  @override
  Map<String, Object?> get toMap => throw UnimplementedError();
}
