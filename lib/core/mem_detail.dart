import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';

class MemDetail {
  final Mem mem;
  final List<MemItemV2> memItems;
  final List<MemNotification>? notifications;

  MemDetail(this.mem, this.memItems, [this.notifications]);

  @override
  String toString() => {
        'mem': mem,
        'memItems': memItems,
        'notifications': notifications,
      }.toString();
}
