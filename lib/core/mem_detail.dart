import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';

class MemDetail {
  final Mem mem;
  final List<MemItem> memItems;
  final MemNotification? notification;

  MemDetail(this.mem, this.memItems, [this.notification]);

  @override
  String toString() => '{'
      ' mem: $mem'
      ', memItems: $memItems'
      ', repeatedNotification: $notification'
      ' }';
}
