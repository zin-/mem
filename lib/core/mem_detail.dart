import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/repositories/mem_item_entity.dart';

// FIXME 定義するべきではない気がする
//  - Mem, MemItems, MemNotificationsの関係はどのレイヤーのもの？
//    - Entity~~かDomain~~
//      - DBのFK制約が絡むしEntityかも
//      - Repositoryも絡んでいくはず
class MemDetail {
  final MemV1 mem;
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
