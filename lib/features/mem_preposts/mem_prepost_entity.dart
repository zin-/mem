import 'package:drift/drift.dart';
import 'package:mem/features/mem_preposts/mem_prepost.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/databases/database.dart' as drift_database;

class MemPrePostEntityV1 with EntityV1<MemPrePost> {
  MemPrePostEntityV1(MemPrePost value) {
    this.value = value;
  }

  factory MemPrePostEntityV1.by(
    int? sourceMemId,
    int targetMemId,
    int minutes,
  ) =>
      MemPrePostEntityV1(
        MemPrePost.of(
          sourceMemId: sourceMemId ?? 0,
          targetMemId: targetMemId,
          minutes: minutes,
        )!,
      );

  @override
  Map<String, Object?> get toMap => {
        'sourceMemId': value.sourceMemId,
        'targetMemId': value.targetMemId,
        'minutes': value.minutes,
      };

  @override
  MemPrePostEntityV1 updatedWith(MemPrePost Function(MemPrePost v) update) =>
      MemPrePostEntityV1(update(value));
}

class SavedMemPrePostEntityV1 extends MemPrePostEntityV1
    with DatabaseTupleEntityV1<int, MemPrePost> {
  SavedMemPrePostEntityV1(Map<String, dynamic> map)
      : super(_prePostFromMap(map)) {
    withBaseColumns(map);
  }

  SavedMemPrePostEntityV1.fromRow(dynamic row) : super(_prePostFromRow(row)) {
    withBaseColumns(row);
  }

  static MemPrePost _prePostFromMap(Map<String, dynamic> map) => MemPrePost.of(
        sourceMemId: map['sourceMemId'],
        targetMemId: map['targetMemId'],
        minutes: map['minutes'] ?? 0,
      )!;

  static MemPrePost _prePostFromRow(dynamic row) => MemPrePost.of(
        sourceMemId: row.sourceMemId,
        targetMemId: row.targetMemId,
        minutes: row.minutes ?? 0,
      )!;

  @override
  SavedMemPrePostEntityV1 updatedWith(
    MemPrePost Function(MemPrePost v) update,
  ) =>
      SavedMemPrePostEntityV1(_savedRowFrom(update(value)));

  factory SavedMemPrePostEntityV1.fromEntityV2(MemPrePostEntity entity) =>
      SavedMemPrePostEntityV1.fromRow(_MemPrePostEntityRow(entity));

  MemPrePostEntity toEntityV2() => MemPrePostEntity(
        value.sourceMemId,
        value.targetMemId,
        value.minutes,
        id,
        createdAt,
        updatedAt,
        archivedAt,
      );

  Map<String, Object?> _savedRowFrom(MemPrePost value) => {
        'id': id,
        'sourceMemId': value.sourceMemId,
        'targetMemId': value.targetMemId,
        'minutes': value.minutes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      };
}

class MemPrePostEntity implements Entity<int> {
  final MemId sourceMemId;
  final MemId targetMemId;
  final int minutes;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  MemPrePostEntity(
    this.sourceMemId,
    this.targetMemId,
    this.minutes,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  );

  factory MemPrePostEntity.fromTuple(dynamic row) => MemPrePostEntity(
        row.sourceMemId,
        row.targetMemId,
        row.minutes ?? 0,
        row.id,
        row.createdAt,
        row.updatedAt,
        row.archivedAt,
      );
}

drift_database.MemPrePostsCompanion convertIntoMemPrePostsInsertable(
  MemPrePost domain,
) =>
    drift_database.MemPrePostsCompanion(
      sourceMemId: Value(domain.sourceMemId),
      targetMemId: Value(domain.targetMemId),
      minutes: Value(domain.minutes),
      createdAt: Value(DateTime.now()),
    );
drift_database.MemPrePostsCompanion convertIntoMemPrePostsUpdateable(
  MemPrePostEntity entity,
) =>
    drift_database.MemPrePostsCompanion(
      sourceMemId: Value(entity.sourceMemId ?? 0),
      targetMemId: Value(entity.targetMemId ?? 0),
      minutes: Value(entity.minutes),
      updatedAt: Value(DateTime.now()),
      archivedAt: Value(entity.archivedAt),
    );

class _MemPrePostEntityRow {
  final MemPrePostEntity entity;

  _MemPrePostEntityRow(this.entity);

  int get id => entity.id;
  int get sourceMemId => entity.sourceMemId!;
  int get targetMemId => entity.targetMemId!;
  int get minutes => entity.minutes;
  DateTime get createdAt => entity.createdAt;
  DateTime? get updatedAt => entity.updatedAt;
  DateTime? get archivedAt => entity.archivedAt;
}
