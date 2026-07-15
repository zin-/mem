import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/view/identifiable.dart';

/// DB persistence metadata（id, createdAt 等）の暫定拡張。
///
/// View 層データ（[EntityV1]）とは責務を分離し、将来廃止予定。
/// metadata は Data / Repository 層（[Entity]）に属する。
mixin DatabaseTupleEntityV1<PRIMARY_KEY, T> on EntityV1<T>
    implements Identifiable<PRIMARY_KEY> {
  @override
  late PRIMARY_KEY id;
  late DateTime createdAt;
  late DateTime? updatedAt;
  late DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  void withBaseColumns(dynamic row) {
    if (row is Map) {
      id = row['id'] as PRIMARY_KEY;
      createdAt = _readDateTime(row['createdAt'])!;
      updatedAt = _readDateTime(row['updatedAt']);
      archivedAt = _readDateTime(row['archivedAt']);
      return;
    }
    id = row.id as PRIMARY_KEY;
    createdAt = _readDateTime(row.createdAt)!;
    updatedAt = _readDateTime(row.updatedAt);
    archivedAt = _readDateTime(row.archivedAt);
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return value as DateTime;
  }

  @override
  Map<String, Object?> get toMap => super.toMap
    ..addAll({
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'archivedAt': archivedAt,
    });
}
