import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_repeated_notification.dart';

class MemDetail {
  final Mem mem;
  final List<MemItem> memItems;
  final MemRepeatedNotification? repeatedNotification;

  MemDetail(this.mem, this.memItems, [this.repeatedNotification]);

  @override
  String toString() => '{'
      ' mem: $mem'
      ', memItems: $memItems'
      ', repeatedNotification: $repeatedNotification'
      ' }';
}
