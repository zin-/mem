import 'package:collection/collection.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';

class MemService {
  final MemRepository _memRepository;
  final MemItemRepository _memItemRepository;
  final MemNotificationRepository _memNotificationRepository;
  final TargetRepository _targetRepository;
  final MemRelationRepository _memRelationRepository;

  Future<
      (
        List<MemItemEntityV1>,
        List<MemNotificationEntity>?,
        TargetEntityV1?,
        List<MemRelationEntityV1>?,
        MemEntity,
      )> save(
    (
      MemEntityV1,
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

          final savedMemEntity = (mem is SavedMemEntityV1 && !undo
              ? await _memRepository.replaceV2(mem.toEntityV2())
              : await _memRepository.receiveV2(mem.value));

          final savedMemItems = await Future.wait(
            memDetail.$2.map(
              (e) => (e is SavedMemItemEntityV1 && !undo
                  ? _memItemRepository.replaceV2(
                      (e.copiedWith(memId: () => savedMemEntity.id)
                              as SavedMemItemEntityV1)
                          .toEntityV2(),
                    )
                  : _memItemRepository.receiveV2(
                      e.copiedWith(memId: () => savedMemEntity.id).toDomain(),
                    )),
            ),
          );

          final memNotifications = memDetail.$3;
          final returnMemNotifications =
              List<MemNotificationEntity?>.empty(growable: true);
          if (memNotifications == null) {
            await _memNotificationRepository.wasteV2(memId: savedMemEntity.id);
          } else {
            returnMemNotifications.addAll(await Future.wait(memNotifications
                .where((e) => !e.value.isRepeatByDayOfWeek())
                .map((e) {
              if (e.value.isEnabled()) {
                return (e is SavedMemNotificationEntityV1 && !undo
                    ? _memNotificationRepository.replaceV2(
                        e
                            .updatedWith(
                              (v) => MemNotification.by(
                                  savedMemEntity.id, v.type, v.time, v.message),
                            )
                            .toEntityV2(),
                      )
                    : _memNotificationRepository.receiveV2(
                        MemNotification.by(
                          savedMemEntity.id,
                          e.value.type,
                          e.value.time,
                          e.value.message,
                        ),
                      ));
              } else {
                return _memNotificationRepository
                    .wasteV2(
                      memId: savedMemEntity.id,
                      type: e.value.type,
                    )
                    .then((v) => null);
              }
            })));

            await _memNotificationRepository.wasteV2(
              memId: savedMemEntity.id,
              type: MemNotificationType.repeatByDayOfWeek,
            );
            for (var entry in memNotifications
                .where((e) => e.value.isRepeatByDayOfWeek())
                .groupListsBy((e) => e.value.time)
                .entries) {
              returnMemNotifications.add(
                await _memNotificationRepository.receiveV2(
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
            await _targetRepository.wasteV2(
              condition: Equals(defFkTargetMemId, savedMemEntity.id),
            );
          } else if (target is SavedTargetEntityV1) {
            savedTarget = await _targetRepository
                .replaceV2(target.toEntityV2())
                .then((v) => SavedTargetEntityV1.fromEntityV2(v));
          } else {
            savedTarget = await _targetRepository
                .receiveV2(
                  target
                      .updatedWith(
                        (v) => Target(
                          memId: savedMemEntity.id,
                          targetType: v.targetType,
                          targetUnit: v.targetUnit,
                          value: v.value,
                          period: v.period,
                        ),
                      )
                      .value,
                )
                .then((v) => SavedTargetEntityV1.fromEntityV2(v));
          }

          // memRelationsの保存ロジック
          final memRelations = memDetail.$5;
          final returnMemRelations =
              List<SavedMemRelationEntityV1?>.empty(growable: true);
          if (memRelations != null) {
            if (memRelations.isEmpty) {
              await _memRelationRepository.wasteV2(
                condition:
                    Equals(defFkMemRelationsSourceMemId, savedMemEntity.id),
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
                  return await _memRelationRepository.replaceV2(e.toEntityV2());
                } else {
                  return await _memRelationRepository.receiveV2(e.value);
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
            savedMemEntity,
          );
        },
        {
          'memDetail': memDetail,
          'undo': undo,
        },
      );

  Future<SavedMemEntityV1> doneByMemId(
    int memId,
  ) =>
      i(
        () async {
          final memEntity = await _memRepository.shipById(
            memId,
            loadChildren: MemRepository.loadLatestActChild,
          );

          final doneMem =
              memEntity.updatedWith(update: (mem) => mem.done(DateTime.now()));

          await save(
            (
              SavedMemEntityV1.fromEntityV2(doneMem),
              [],
              null,
              null,
              null,
            ),
          );
          final reloaded = await _memRepository.shipById(
            memId,
            loadChildren: MemRepository.loadLatestActChild,
          );
          return SavedMemEntityV1.fromEntityV2(reloaded);
        },
        {
          'memId': memId,
        },
      );

  Future<SavedMemEntityV1> undoneByMemId(
    int memId,
  ) =>
      i(
        () async {
          final memEntity = await _memRepository.shipById(
            memId,
            loadChildren: MemRepository.loadLatestActChild,
          );
          final undoneMem =
              memEntity.updatedWith(update: (mem) => mem.undone());

          await save(
            (
              SavedMemEntityV1.fromEntityV2(undoneMem),
              [],
              null,
              null,
              null,
            ),
          );
          final reloaded = await _memRepository.shipById(
            memId,
            loadChildren: MemRepository.loadLatestActChild,
          );
          return SavedMemEntityV1.fromEntityV2(reloaded);
        },
        {
          'memId': memId,
        },
      );

  Future<MemEntity> archive(SavedMemEntityV1 mem) => i(
        () async {
          final archivedMem = await _memRepository.replaceV2(
              mem.toEntityV2().updatedWith(archivedAt: () => DateTime.now()));

          await _memItemRepository.archiveBy(memId: archivedMem.id);
          await _memRelationRepository.archiveByV2(
              relatedMemId: archivedMem.id);

          return await _memRepository.shipById(
            archivedMem.id,
            loadChildren: MemRepository.loadLatestActChild,
          );
        },
        {
          'mem': mem,
        },
      );

  Future<MemEntity> unarchive(SavedMemEntityV1 mem) => i(
        () async {
          final unarchivedMem =
              await _memRepository.replaceV2(mem.toEntityV2().updatedWith(
                    updatedAt: () => DateTime.now(),
                    archivedAt: () => null,
                  ));

          await _memItemRepository.unarchiveBy(memId: unarchivedMem.id).then(
              (v) =>
                  v.map((e) => SavedMemItemEntityV1.fromEntityV2(e)).toList());
          await _memRelationRepository.unarchiveByV2(
            condition: Or([
              Equals(defFkMemRelationsSourceMemId, unarchivedMem.id),
              Equals(defFkMemRelationsTargetMemId, unarchivedMem.id),
            ]),
          );

          return await _memRepository.shipById(
            unarchivedMem.id,
            loadChildren: MemRepository.loadLatestActChild,
          );
        },
        {
          'mem': mem,
        },
      );

  Future<bool> remove(int memId) => v(
        () async {
          await _memRepository.wasteV2(id: memId);

          return true;
        },
        {
          'memId': memId,
        },
      );

  MemService._(
    this._memRepository,
    this._memItemRepository,
    this._memNotificationRepository,
    this._targetRepository,
    this._memRelationRepository,
  );

  static MemService? _instance;

  factory MemService({
    MemRepository? memRepository,
    MemItemRepository? memItemRepository,
    MemNotificationRepository? memNotificationRepository,
    TargetRepository? targetRepository,
    MemRelationRepository? memRelationRepository,
  }) =>
      i(
        () => _instance ??= MemService._(
          memRepository ?? MemRepository(),
          memItemRepository ?? MemItemRepository(),
          memNotificationRepository ?? MemNotificationRepository(),
          targetRepository ?? TargetRepository(),
          memRelationRepository ?? MemRelationRepository(),
        ),
      );
}
