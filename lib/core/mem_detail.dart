import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';

class MemDetail {
  final Mem mem;
  final List<MemItem> memItems;

  MemDetail(this.mem, this.memItems);

  @override
  String toString() => '{'
      ' mem: $mem'
      ', memItems: $memItems'
      ' }';
}
