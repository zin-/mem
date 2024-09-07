enum MemItemType {
  memo,
}

class MemItemV2 {
  final int? memId;
  final MemItemType type;
  final dynamic value;

  MemItemV2(this.memId, this.type, this.value);
}
