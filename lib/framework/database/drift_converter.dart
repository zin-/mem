import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mem_items/mem_item.dart' as mem_item_domain;
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation.dart'
    as mem_relation_domain;
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mems/mem.dart' as mem_domain;
import 'package:mem/features/mems/mem_entity.dart' as mem_entity;
import 'package:mem/features/targets/target.dart' as target_domain;
import 'package:mem/features/targets/target_entity.dart';

dynamic convertIntoDriftInsertable(dynamic domain) {
  switch (domain) {
    case mem_domain.Mem _:
      return convertIntoMemsInsertable(domain, DateTime.now());

    case mem_item_domain.MemItem _:
      return convertIntoMemItemsInsertable(domain, DateTime.now());

    case ActiveAct _:
    case FinishedAct _:
    case PausedAct _:
      return convertIntoActsInsertable(domain, createdAt: DateTime.now());

    case MemNotification _:
      return convertIntoMemRepeatedNotificationsInsertable(
        domain,
        createdAt: DateTime.now(),
      );

    case target_domain.Target _:
      return convertIntoTargetsInsertable(domain);

    case mem_relation_domain.MemRelation _:
      return convertIntoMemRelationsInsertable(domain);

    default:
      throw StateError('入力おかしいかも: ${domain.runtimeType}');
  }
}

dynamic convertIntoDriftUpdateable(
  dynamic entity,
) {
  switch (entity) {
    case mem_entity.MemEntity _:
      return convertIntoMemsUpdateable(entity);
    case MemItemEntity _:
      return convertIntoMemItemsUpdateable(entity);
    case ActEntity _:
      return convertIntoActsUpdateable(entity);
    case MemNotificationEntity _:
      return convertIntoMemRepeatedNotificationsUpdateable(entity);
    case TargetEntity _:
      return convertIntoTargetsUpdateable(entity);

    case MemRelationEntity _:
      return convertIntoMemRelationsUpdateable(entity);

    default:
      throw StateError('入力おかしいかも: ${entity.runtimeType}');
  }
}
