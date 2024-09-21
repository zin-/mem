import 'package:mem/mems/mem_notification.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_item_entity.dart';

// FIXME 定義するべきではない気がする
//  - Mem, MemItems, MemNotificationsの関係はどのレイヤーのもの？
//    - Entity~~かDomain~~
//      - DBのFK制約が絡むしEntityかも
//      - Repositoryも絡んでいくはず
class MemDetail {
  final MemEntity mem;
  final List<MemItemEntity> memItems;
  final List<MemNotification>? notifications;

  MemDetail(this.mem, this.memItems, [this.notifications]);

  @override
  String toString() => {
        'mem': mem,
        'memItems': memItems,
        'notifications': notifications,
      }.toString();
}
