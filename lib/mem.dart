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

  // FIXME エレガントじゃない気がする
  Mem.copiedFrom(Mem mem)
      : id = mem.id,
        name = mem.name,
        doneAt = mem.doneAt,
        createdAt = mem.createdAt,
        updatedAt = mem.updatedAt,
        archivedAt = mem.archivedAt;
}
