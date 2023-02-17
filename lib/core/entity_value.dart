// TODO 保存済みの値は型の違いで表現する
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

  bool isArchived() => archivedAt != null;
}
