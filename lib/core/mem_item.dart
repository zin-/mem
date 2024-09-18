enum MemItemType {
  memo,
}

class MemItem {
  final int? memId;
  final MemItemType type;
  final dynamic value;

  MemItem(this.memId, this.type, this.value);
}
