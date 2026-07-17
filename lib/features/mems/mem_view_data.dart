import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_period_db.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/view/identifiable.dart';

/// Mem の view 層データ（編集・表示用）。
///
/// Issue #603 の「ViewModel」は旧称・暫定呼称。
/// MVVM の ViewModel（Riverpod Notifier 等）とは異なり、
/// immutable な domain データ（[Mem]）のラッパーである。
///
/// DB persistence metadata（createdAt / updatedAt / archivedAt）は
/// 責務が異なるため保持しない。metadata は Data 層の [MemEntity] に属する。
class MemViewData with EntityV1<Mem> implements Identifiable<int> {
  MemViewData(Mem value) {
    this.value = value;
  }

  bool get isSaved => value.id != null;

  @override
  int get id => value.id!;

  factory MemViewData.newMem() => MemViewData(Mem(null, "", null, null));

  factory MemViewData.fromEntityV2(MemEntity entity) =>
      MemViewData(entity.toDomain());

  @override
  Map<String, Object?> get toMap {
    final periodDb = periodToDb(value.period);
    return {
      if (isSaved) 'id': value.id,
      'name': value.name,
      'doneAt': value.doneAt,
      'notifyOn': periodDb.notifyOn,
      'notifyAt': periodDb.notifyAt,
      'endOn': periodDb.endOn,
      'endAt': periodDb.endAt,
    };
  }

  // metadata は MemViewData が保持しないため、更新保存時は既存 [MemEntity] から
  // createdAt / updatedAt / archivedAt を引き継ぐ（呼び出し側が渡す）。
  // metadata 引き継ぎの本格整理は #463 前後で行う。
  MemEntity toEntityV2({
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) =>
      MemEntity(
        value.id!,
        value.name,
        value.doneAt,
        value.period,
        null,
        createdAt ?? DateTime.now(),
        updatedAt,
        archivedAt,
        latestAct: value.latestAct,
        scheduleAnchorAct: value.scheduleAnchorAct,
        repeatedNotifications: null,
        memRelations: null,
      );

  @override
  MemViewData updatedWith(Mem Function(Mem mem) update) =>
      MemViewData(update(value));
}
