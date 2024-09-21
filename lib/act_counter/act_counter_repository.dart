import 'package:mem/act_counter/act_counter_entity.dart';
import 'package:mem/framework/repository/home_widget_repository.dart';

class ActCounterRepository
    extends HomeWidgetRepository<ActCounterEntity, SavedActCounterEntity> {
  @override
  SavedActCounterEntity pack(Map<String, dynamic> map) =>
      SavedActCounterEntity.fromMap(map)..homeWidgetId = map['homeWidgetId'];
}
