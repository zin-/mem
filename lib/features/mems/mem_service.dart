import 'package:collection/collection.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';

class MemService {
  final MemRepository _memRepository;
  final TargetRepository _targetRepository;

  Future<
      (
        List<MemItemEntityV1>,
        List<MemNotificationEntity>?,
        TargetEntityV1?,
        List<MemRelationEntityV1>?,
        MemEntity,
      )> save(
    (
      MemViewData,
      List<MemItemEntityV1>,
      List<MemNotificationEntityV1>?,
      TargetEntityV1?,
      List<MemRelationEntityV1>?,
    ) memDetail, {
    bool undo = false,
  }) =>
      i(
        () async {
          final mem = memDetail.$1;

          MemEntity? existing;
          if (mem.isSaved && !undo) {
            existing = await _memRepository.shipById(
              mem.id,
              loadLatestAct: true,
            );
          }

          final MemEntity savedMemEntity;
          if (mem.isSaved && !undo) {
            final replacing = <MemItemEntity>[];
            final receiving = <MemItem>[];
            for (final item in memDetail.$2) {
              if (item is SavedMemItemEntityV1) {
                replacing.add(
                  (item.copiedWith(memId: () => mem.id) as SavedMemItemEntityV1)
                      .toEntityV2(),
                );
              } else {
                receiving.add(
                  item.copiedWith(memId: () => mem.id).toDomain(),
                );
              }
            }
            final entity = mem.toEntityV2(
              createdAt: existing!.createdAt,
              updatedAt: DateTime.now(),
              archivedAt: existing.archivedAt,
            );
            savedMemEntity = await _memRepository.replace(
              replacing.isEmpty
                  ? entity
                  : entity.updatedWith(items: () => replacing),
              receivingItems: receiving,
            );
          } else {
            savedMemEntity = await _memRepository.receive(
              mem.value,
              items: [
                for (final item in memDetail.$2) item.toDomain(),
              ],
            );
          }

          final savedMemItems = savedMemEntity.items ?? const <MemItemEntity>[];

          final memNotifications = memDetail.$3;
          final returnMemNotifications =
              List<MemNotificationEntity?>.empty(growable: true);
          if (memNotifications == null) {
            await _memRepository.wasteRepeatedNotifications(
              memId: savedMemEntity.id,
            );
          } else {
            returnMemNotifications.addAll(await Future.wait(memNotifications
                .where((e) => !e.value.isRepeatByDayOfWeek())
                .map((e) {
              if (e.value.isEnabled()) {
                return (e is SavedMemNotificationEntityV1 && !undo
                    ? _memRepository.replaceRepeatedNotification(
                        e
                            .updatedWith(
                              (v) => MemNotification.by(
                                  savedMemEntity.id, v.type, v.time, v.message),
                            )
                            .toEntityV2(),
                      )
                    : _memRepository.receiveRepeatedNotification(
                        MemNotification.by(
                          savedMemEntity.id,
                          e.value.type,
                          e.value.time,
                          e.value.message,
                        ),
                      ));
              } else {
                return _memRepository
                    .wasteRepeatedNotifications(
                      memId: savedMemEntity.id,
                      type: e.value.type,
                    )
                    .then((v) => null);
              }
            })));

            await _memRepository.wasteRepeatedNotifications(
              memId: savedMemEntity.id,
              type: MemNotificationType.repeatByDayOfWeek,
            );
            for (var entry in memNotifications
                .where((e) => e.value.isRepeatByDayOfWeek())
                .groupListsBy((e) => e.value.time)
                .entries) {
              returnMemNotifications.add(
                await _memRepository.receiveRepeatedNotification(
                  MemNotification.by(
                    savedMemEntity.id,
                    entry.value.single.value.type,
                    entry.value.single.value.time,
                    entry.value.single.value.message,
                  ),
                ),
              );
            }
          }

          SavedTargetEntityV1? savedTarget;
          final target = memDetail.$4;
          if (target == null || target.value.value == 0) {
            await _targetRepository.waste(memId: savedMemEntity.id);
          } else if (target is SavedTargetEntityV1) {
            savedTarget = await _targetRepository
                .replace(target.toEntityV2())
                .then((v) => SavedTargetEntityV1.fromEntityV2(v));
          } else {
            savedTarget = await _targetRepository
                .receive(
                  target
                      .updatedWith(
                        (v) => Target(
                          memId: savedMemEntity.id,
                          targetType: v.targetType,
                          targetUnit: v.targetUnit,
                          value: v.value,
                          period: v.period,
                          secondsAfterLastAct: v.secondsAfterLastAct,
                        ),
                      )
                      .value,
                )
                .then((v) => SavedTargetEntityV1.fromEntityV2(v));
          }

          final memRelations = memDetail.$5;
          final returnMemRelations =
              List<SavedMemRelationEntityV1?>.empty(growable: true);
          if (memRelations != null) {
            if (memRelations.isEmpty) {
              await _memRepository.wasteRelations(
                sourceMemId: savedMemEntity.id,
              );
            } else {
              final saved = await Future.wait(memRelations
                  .map((e) => e.updatedWith((v) => MemRelation.by(
                        savedMemEntity.id,
                        v.targetMemId,
                        v.type,
                        v.value,
                      )))
                  .map((e) async {
                if (e is SavedMemRelationEntityV1 && !undo) {
                  return await _memRepository.replaceRelation(e.toEntityV2());
                } else {
                  return await _memRepository.receiveRelation(e.value);
                }
              }));
              returnMemRelations.addAll(
                  saved.map((e) => SavedMemRelationEntityV1.fromEntityV2(e)));
            }
          }

          return (
            savedMemItems
                .map((e) => SavedMemItemEntityV1.fromEntityV2(e))
                .toList(),
            returnMemNotifications.nonNulls.toList(growable: false),
            savedTarget,
            returnMemRelations.nonNulls.toList(growable: false),
            savedMemEntity.updatedWith(
              target: () => savedTarget?.value,
            ),
          );
        },
        {
          'memDetail': memDetail,
          'undo': undo,
        },
      );

  Future<MemEntity> doneByMemId(
    int memId,
  ) =>
      i(
        () async {
          final memEntity = await _memRepository.shipById(
            memId,
            loadLatestAct: true,
          );

          final doneMem =
              memEntity.updatedWith(update: (mem) => mem.done(DateTime.now()));

          await save(
            (
              MemViewData.fromEntityV2(doneMem),
              [],
              null,
              null,
              null,
            ),
          );
          return await _memRepository.shipById(
            memId,
            loadLatestAct: true,
          );
        },
        {
          'memId': memId,
        },
      );

  Future<MemEntity> undoneByMemId(
    int memId,
  ) =>
      i(
        () async {
          final memEntity = await _memRepository.shipById(
            memId,
            loadLatestAct: true,
          );
          final undoneMem =
              memEntity.updatedWith(update: (mem) => mem.undone());

          await save(
            (
              MemViewData.fromEntityV2(undoneMem),
              [],
              null,
              null,
              null,
            ),
          );
          return await _memRepository.shipById(
            memId,
            loadLatestAct: true,
          );
        },
        {
          'memId': memId,
        },
      );

  Future<MemEntity> archive(MemEntity mem) => i(
        () async {
          // items を渡すと replace が item 行を書き換える。archive は archiveItems に任せる
          final archivedMem = await _memRepository.replace(
            mem.updatedWith(
              archivedAt: () => DateTime.now(),
              items: () => null,
            ),
          );

          await _memRepository.archiveItems(archivedMem.id);
          await _memRepository.archiveRelations(relatedMemId: archivedMem.id);

          return await _memRepository.shipById(
            archivedMem.id,
            loadLatestAct: true,
          );
        },
        {
          'mem': mem,
        },
      );

  Future<MemEntity> unarchive(MemEntity mem) => i(
        () async {
          final unarchivedMem = await _memRepository.replace(
            mem.updatedWith(
              updatedAt: () => DateTime.now(),
              archivedAt: () => null,
              items: () => null,
            ),
          );

          await _memRepository.unarchiveItems(unarchivedMem.id);
          await _memRepository.unarchiveRelations(
            relatedMemId: unarchivedMem.id,
          );

          return await _memRepository.shipById(
            unarchivedMem.id,
            loadLatestAct: true,
          );
        },
        {
          'mem': mem,
        },
      );

  Future<bool> remove(int memId) => v(
        () async {
          await _memRepository.waste(id: memId);

          return true;
        },
        {
          'memId': memId,
        },
      );

  MemService._(
    this._memRepository,
    this._targetRepository,
  );

  static MemService? _instance;

  static void resetSingleton() => i(
        () {
          _instance = null;
        },
        {'_instance': _instance},
      );

  factory MemService({
    MemRepository? memRepository,
    TargetRepository? targetRepository,
  }) =>
      i(
        () => _instance ??= MemService._(
          memRepository ?? MemRepository(),
          targetRepository ?? TargetRepository(),
        ),
      );
}
