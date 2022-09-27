class Mem {
  final int? id;
  String name;
  DateTime? doneAt;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  Mem(
    this.id,
    this.name,
    this.doneAt,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  );

  bool isArchived() => id != null && createdAt != null && archivedAt != null;

  // FIXME エレガントじゃない気がする
  Mem.copyFrom(Mem mem)
      : id = mem.id,
        name = mem.name,
        doneAt = mem.doneAt,
        createdAt = mem.createdAt,
        updatedAt = mem.updatedAt,
        archivedAt = mem.archivedAt;
}

enum MemItemType {
  memo,
}

class MemItem {
  final int? id;
  int? memId;
  final MemItemType type;
  dynamic value;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  MemItem({
    this.id,
    this.memId,
    required this.type,
    this.value,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });
}
