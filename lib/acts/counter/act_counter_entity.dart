import 'package:mem/acts/counter/act_counter.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/home_widget_entity.dart';

class ActCounterEntity extends ActCounter with Entity, HomeWidgetEntity {
  ActCounterEntity(super.memId, super.name, super.actCount, super.updatedAt)
      : super();

  @override
  Map<String, dynamic> get toMap => {
        'initializeMethodName': initializeMethodName,
        'methodChannelName': methodChannelName,
        'memId': memId,
        'name': name,
        'actCount': actCount,
        'updatedAt': updatedAt,
      };

  @override
  Map<String, dynamic> get toWidgetData => {
        "memName-$memId": name,
        "actCount-$memId": actCount,
        "lastUpdatedAtSeconds-$memId":
            updatedAt?.millisecondsSinceEpoch.toDouble(),
      };

  ActCounterEntity.from(super.savedMem, super.savedActs) : super.from();
}

class SavedActCounterEntity extends ActCounterEntity
    with SavedHomeWidgetEntity {
  SavedActCounterEntity.fromMap(Map<String, dynamic> map)
      : super(
          map['memId'],
          map['name'],
          map['actCount'],
          map['updatedAt'],
        );

  @override
  Map<String, dynamic> get toWidgetData => super.toWidgetData
    ..addAll({
      "memId-$homeWidgetId": memId,
    });
}
