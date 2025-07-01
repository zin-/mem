import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';

// FIXME 定義するべきではない気がする
//  - Mem, MemItems, MemNotificationsの関係はどのレイヤーのもの？
//    - Entity~~かDomain~~
//      - DBのFK制約が絡むしEntityかも
//      - Repositoryも絡んでいくはず
class MemDetail {
  final MemEntityV2 mem;
  final List<MemItemEntityV2> memItems;
  final List<MemNotificationEntityV2>? notifications;
  final TargetEntity? target;
  final List<MemRelationEntity>? memRelations;

  MemDetail(this.mem, this.memItems,
      [this.notifications, this.target, this.memRelations]);

  @override
  String toString() => {
        'mem': mem,
        'memItems': memItems,
        'notifications': notifications,
        'target': target,
        'memRelations': memRelations,
      }.toString();
}
