import 'package:collection/collection.dart';
import 'package:mem/mems/mem_detail.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_item_entity.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/mems/mem_notification_repository.dart';
import 'package:mem/mems/mem_repository.dart';

class MemService {
  final MemRepositoryV2 _memRepository;
  final MemItemRepositoryV2 _memItemRepository;
  final MemNotificationRepositoryV2 _memNotificationRepository;

  Future<MemDetail> save(
    MemDetail memDetail, {
    bool undo = false,
  }) =>
      i(
        () async {
          final mem = memDetail.mem;

          final savedMem = (mem is SavedMemEntityV2 && !undo
              ? await _memRepository.replace(mem)
              : await _memRepository.receive(mem));

          final savedMemItems = await Future.wait(
            memDetail.memItems.map(
              (e) => (e is SavedMemItemEntityV2 && !undo
                  ? _memItemRepository.replace(
                      e.copiedWith(memId: () => savedMem.id)
                          as SavedMemItemEntityV2,
                    )
                  : _memItemRepository.receive(
                      e.copiedWith(memId: () => savedMem.id),
                    )),
            ),
          );

          final memNotifications = memDetail.notifications;
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
                        (v) => MemNotification(
                            savedMem.id, v.type, v.time, v.message),
                      ))
                    : _memNotificationRepository.receive(e.updatedWith(
                        (v) => MemNotification(
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
                    (v) => MemNotification(
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

          return MemDetail(
            savedMem,
            savedMemItems,
            returnMemNotifications.nonNulls.toList(growable: false),
          );
        },
        {
          'memDetail': memDetail,
          'undo': undo,
        },
      );

  Future<MemDetail> doneByMemId(
    int memId,
  ) =>
      i(
        () async => save(
          MemDetail(
            await _memRepository.ship(id: memId).then(
                  (v) => v.single.updatedWith(
                    (mem) => mem.done(DateTime.now()),
                  ),
                ),
            [],
          ),
        ),
        {
          'memId': memId,
        },
      );

  Future<MemDetail> undoneByMemId(
    int memId,
  ) =>
      i(
        () async => save(
          MemDetail(
            await _memRepository.ship(id: memId).then(
                  (v) => v.single.updatedWith(
                    (mem) => mem.undone(),
                  ),
                ),
            [],
          ),
        ),
        {
          'memId': memId,
        },
      );

  Future<MemDetail> archive(SavedMemEntityV2 mem) => i(
        () async {
          final archivedMem = await _memRepository.archive(mem);
          final archivedMemItems =
              await _memItemRepository.archiveBy(memId: archivedMem.id);
          final archivedMemNotifications =
              await _memNotificationRepository.archiveBy(memId: archivedMem.id);

          return MemDetail(
            archivedMem,
            archivedMemItems.toList(growable: false),
            archivedMemNotifications.toList(growable: false),
          );
        },
        {
          'mem': mem,
        },
      );

  Future<MemDetail> unarchive(SavedMemEntityV2 mem) => i(
        () async {
          final unarchivedMem = await _memRepository.unarchive(mem);
          final unarchivedMemItems =
              await _memItemRepository.unarchiveBy(memId: unarchivedMem.id);
          final unarchivedMemNotifications = await _memNotificationRepository
              .unarchiveBy(memId: unarchivedMem.id);

          return MemDetail(
            unarchivedMem,
            unarchivedMemItems.toList(growable: false),
            unarchivedMemNotifications.toList(growable: false),
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
  );

  static MemService? _instance;

  factory MemService() => i(
        () => _instance ??= MemService._(
          MemRepositoryV2(),
          MemItemRepositoryV2(),
          MemNotificationRepositoryV2(),
        ),
      );
}
