import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_item_entity.dart';
import 'package:mem/mems/mem_notification_entity.dart';

// FIXME 定義するべきではない気がする
//  - Mem, MemItems, MemNotificationsの関係はどのレイヤーのもの？
//    - Entity~~かDomain~~
//      - DBのFK制約が絡むしEntityかも
//      - Repositoryも絡んでいくはず
class MemDetail {
  final MemEntityV2 mem;
  final List<MemItemEntityV2> memItems;
  final List<MemNotificationEntityV2>? notifications;

  MemDetail(this.mem, this.memItems, [this.notifications]);

  @override
  String toString() => {
        'mem': mem,
        'memItems': memItems,
        'notifications': notifications,
      }.toString();
}
