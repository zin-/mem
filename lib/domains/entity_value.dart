abstract class EntityValue {
  final dynamic id;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  EntityValue({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  bool isSaved() => id != null && createdAt != null;

  bool isArchived() => isSaved() && archivedAt != null;

  @override
  String toString() => {
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      }.toString();
}
