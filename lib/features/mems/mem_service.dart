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
        MemEntityV2,
        List<MemItemEntity>,
        List<MemNotificationEntity>?,
        TargetEntity?,
        List<MemRelationEntity>?
      )> save(
    (
      MemEntityV2,
      List<MemItemEntity>,
      List<MemNotificationEntity>?,
      TargetEntity?,
      List<MemRelationEntity>?
    ) memDetail, {
    bool undo = false,
  }) =>
      i(
        () async {
          final mem = memDetail.$1;

          final savedMem = (mem is SavedMemEntityV2 && !undo
              ? await _memRepository.replace(mem)
              : await _memRepository.receive(mem));

          final savedMemItems = await Future.wait(
            memDetail.$2.map(
              (e) => (e is SavedMemItemEntity && !undo
                  ? _memItemRepository.replace(
                      e.copiedWith(memId: () => savedMem.id)
                          as SavedMemItemEntity,
                    )
                  : _memItemRepository.receive(
                      e.copiedWith(memId: () => savedMem.id),
                    )),
            ),
          );

          final memNotifications = memDetail.$3;
          final returnMemNotifications =
              List<SavedMemNotificationEntityV2?>.empty(growable: true);
          if (memNotifications == null) {
            await _memNotificationRepository.waste(memId: savedMem.id);
          } else {
            returnMemNotifications.addAll(await Future.wait(memNotifications
                .where((e) => !e.value.isRepeatByDayOfWeek())
                .map((e) {
              if (e.value.isEnabled()) {
                return (e is SavedMemNotificationEntityV2 && !undo
                    ? _memNotificationRepository.replace(e.updatedWith(
                        (v) => MemNotification.by(
                            savedMem.id, v.type, v.time, v.message),
                      ))
                    : _memNotificationRepository.receive(e.updatedWith(
                        (v) => MemNotification.by(
                            savedMem.id, v.type, v.time, v.message),
                      )));
              } else {
                return _memNotificationRepository
                    .waste(
                      memId: savedMem.id,
                      type: e.value.type,
                    )
                    .then((v) => null);
              }
            })));

            await _memNotificationRepository.waste(
              memId: savedMem.id,
              type: MemNotificationType.repeatByDayOfWeek,
            );
            for (var entry in memNotifications
                .where((e) => e.value.isRepeatByDayOfWeek())
                .groupListsBy((e) => e.value.time)
                .entries) {
              returnMemNotifications.add(
                await _memNotificationRepository.receive(
                  entry.value.single.updatedWith(
                    (v) => MemNotification.by(
                      savedMem.id,
                      v.type,
                      v.time,
                      v.message,
                    ),
                  ),
                ),
              );
            }
          }

          SavedTargetEntity? savedTarget;
          final target = memDetail.$4;
          if (target == null || target.value.value == 0) {
            await _targetRepository.waste(
              condition: Equals(defFkTargetMemId, savedMem.id),
            );
          } else if (target is SavedTargetEntity) {
            savedTarget = await _targetRepository.replace(target);
          } else {
            savedTarget = await _targetRepository.receive(target.updatedWith(
              (v) => Target(
                memId: savedMem.id,
                targetType: v.targetType,
                targetUnit: v.targetUnit,
                value: v.value,
                period: v.period,
              ),
            ));
          }

          // memRelationsの保存ロジック
          final memRelations = memDetail.$5;
          final returnMemRelations =
              List<SavedMemRelationEntity?>.empty(growable: true);
          if (memRelations != null) {
            if (memRelations.isEmpty) {
              await _memRelationRepository.waste(
                condition: Equals(defFkMemRelationsSourceMemId, savedMem.id),
              );
            } else {
              returnMemRelations.addAll(await Future.wait(memRelations
                  .map((e) => e.updatedWith((v) => MemRelation.by(
                        savedMem.id,
                        v.targetMemId,
                        v.type,
                        v.value,
                      )))
                  .map((e) {
                if (e is SavedMemRelationEntity && !undo) {
                  return _memRelationRepository.replace(e);
                } else {
                  return _memRelationRepository.receive(e);
                }
              })));
            }
          }

          return (
            savedMem,
            savedMemItems,
            returnMemNotifications.nonNulls.toList(growable: false),
            savedTarget,
            returnMemRelations.nonNulls.toList(growable: false)
          );
        },
        {
          'memDetail': memDetail,
          'undo': undo,
        },
      );

  Future<
      (
        MemEntityV2,
        List<MemItemEntity>,
        List<MemNotificationEntity>?,
        TargetEntity?,
        List<MemRelationEntity>?
      )> doneByMemId(
    int memId,
  ) =>
      i(
        () async => save(
          (
            await _memRepository.ship(id: memId).then(
                  (v) => v.single.updatedWith(
                    (mem) => mem.done(DateTime.now()),
                  ),
                ),
            [],
            null,
            null,
            null,
          ),
        ),
        {
          'memId': memId,
        },
      );

  Future<
      (
        MemEntityV2,
        List<MemItemEntity>,
        List<MemNotificationEntity>?,
        TargetEntity?,
        List<MemRelationEntity>?
      )> undoneByMemId(
    int memId,
  ) =>
      i(
        () async => save(
          (
            await _memRepository.ship(id: memId).then(
                  (v) => v.single.updatedWith(
                    (mem) => mem.undone(),
                  ),
                ),
            [],
            null,
            null,
            null,
          ),
        ),
        {
          'memId': memId,
        },
      );

  Future<
      (
        MemEntityV2,
        List<MemItemEntity>,
        List<MemNotificationEntity>?,
        TargetEntity?,
        List<MemRelationEntity>?
      )> archive(SavedMemEntityV2 mem) => i(
        () async {
          final archivedMem = await _memRepository.archive(mem);
          final archivedMemItems =
              await _memItemRepository.archiveBy(memId: archivedMem.id);
          final archivedMemNotifications =
              await _memNotificationRepository.archiveBy(memId: archivedMem.id);
          final archivedMemRelations = await _memRelationRepository.archiveBy(
            relatedMemId: archivedMem.id,
          );

          return (
            archivedMem,
            archivedMemItems.toList(growable: false),
            archivedMemNotifications.toList(growable: false),
            null,
            archivedMemRelations.toList(growable: false),
          );
        },
        {
          'mem': mem,
        },
      );

  Future<
      (
        MemEntityV2,
        List<MemItemEntity>,
        List<MemNotificationEntity>?,
        TargetEntity?,
        List<MemRelationEntity>?
      )> unarchive(SavedMemEntityV2 mem) => i(
        () async {
          final unarchivedMem = await _memRepository.unarchive(mem);
          final unarchivedMemItems =
              await _memItemRepository.unarchiveBy(memId: unarchivedMem.id);
          final unarchivedMemNotifications = await _memNotificationRepository
              .unarchiveBy(memId: unarchivedMem.id);
          final unarchivedMemRelations =
              await _memRelationRepository.unarchiveBy(
            condition: Or([
              Equals(defFkMemRelationsSourceMemId, unarchivedMem.id),
              Equals(defFkMemRelationsTargetMemId, unarchivedMem.id),
            ]),
          );

          return (
            unarchivedMem,
            unarchivedMemItems.toList(growable: false),
            unarchivedMemNotifications.toList(growable: false),
            null,
            unarchivedMemRelations.toList(growable: false),
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
    this._memItemRepository,
    this._memNotificationRepository,
    this._targetRepository,
    this._memRelationRepository,
  );

  static MemService? _instance;

  factory MemService() => i(
        () => _instance ??= MemService._(
          MemRepository(),
          MemItemRepository(),
          MemNotificationRepository(),
          TargetRepository(),
          MemRelationRepository(),
        ),
      );
}
