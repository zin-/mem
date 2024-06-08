import 'package:collection/collection.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_item.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

class MemService {
  final MemRepository _memRepository;
  final MemItemRepository _memItemRepository;
  final MemNotificationRepository _memNotificationRepository;

  Future<MemDetail> save(MemDetail memDetail, {bool undo = false}) => i(
        () async {
          final mem = memDetail.mem;

          final savedMem = (mem is SavedMem && !undo
              ? await _memRepository.replace(mem)
              : await _memRepository.receive(mem));

          final savedMemItems = (await Future.wait(
              memDetail.memItems.map((e) => (e is SavedMemItem && !undo
                  ? _memItemRepository.replace(
                      e.copiedWith(memId: () => savedMem.id),
                    )
                  : _memItemRepository.receive(
                      e.copiedWith(memId: () => savedMem.id),
                    )))));

          final memNotifications = memDetail.notifications;
          final returnMemNotifications =
              List<SavedMemNotification?>.empty(growable: true);
          if (memNotifications == null) {
            await _memNotificationRepository.wasteByMemId(savedMem.id);
          } else {
            returnMemNotifications.addAll(await Future.wait(memNotifications
                .where((e) => !e.isRepeatByDayOfWeek())
                .map((e) {
              if (e.isEnabled()) {
                return (e is SavedMemNotification && !undo
                    ? _memNotificationRepository.replace(e.copiedWith(
                        memId: () => savedMem.id,
                      ))
                    : _memNotificationRepository.receive(e.copiedWith(
                        memId: () => savedMem.id,
                      )));
              } else {
                _memNotificationRepository.wasteByMemIdAndType(
                  savedMem.id,
                  e.type,
                );
                return Future.value(null);
              }
            })));

            await _memNotificationRepository.wasteByMemIdAndType(
              savedMem.id,
              MemNotificationType.repeatByDayOfWeek,
            );
            for (var entry in memNotifications
                .where((e) => e.isRepeatByDayOfWeek())
                .groupListsBy((e) => e.time)
                .entries) {
              returnMemNotifications.add(await _memNotificationRepository
                  .receive(entry.value.first.copiedWith(
                memId: () => savedMem.id,
              )));
            }
          }

          return MemDetail(
            savedMem,
            savedMemItems,
            returnMemNotifications.whereType<SavedMemNotification>().toList(),
          );
        },
        {'memDetail': memDetail},
      );

  Future<MemDetail> doneByMemId(int memId) => i(
        () async {
          final done = (await _memRepository.shipById(memId))
              .copiedWith(doneAt: () => DateTime.now());
          return save(MemDetail(done, []));
        },
        {'memId': memId},
      );

  Future<MemDetail> undoneByMemId(int memId) => i(
        () async {
          final undone = (await _memRepository.shipById(memId))
              .copiedWith(doneAt: () => null);
          return save(MemDetail(undone, []));
        },
        {'memId': memId},
      );

  Future<MemDetail> archive(SavedMem mem) => i(
        () async {
          final archivedMem = await _memRepository.archive(mem);
          final archivedMemItems =
              await _memItemRepository.archiveByMemId(archivedMem.id);
          final archivedMemNotifications =
              await _memNotificationRepository.archiveByMemId(archivedMem.id);

          return MemDetail(
            archivedMem,
            archivedMemItems.toList(),
            archivedMemNotifications.toList(),
          );
        },
        {
          "mem": mem,
        },
      );

  Future<MemDetail> unarchive(SavedMem mem) => i(
        () async {
          final unarchivedMem = await _memRepository.unarchive(mem);
          final unarchivedMemItems =
              await _memItemRepository.unarchiveByMemId(unarchivedMem.id);
          final unarchivedMemNotifications = await _memNotificationRepository
              .unarchiveByMemId(unarchivedMem.id);

          return MemDetail(
            unarchivedMem,
            unarchivedMemItems.toList(growable: false),
            unarchivedMemNotifications.toList(growable: false),
          );
        },
        mem,
      );

  Future<bool> remove(int memId) => v(
        () async {
          // TODO https://github.com/zin-/mem/issues/284
          await _memNotificationRepository.wasteByMemId(memId);
          await _memItemRepository.wasteByMemId(memId);
          await _memRepository.wasteById(memId);

          return true;
        },
        {'memId': memId},
      );

  MemService._(
    this._memRepository,
    this._memItemRepository,
    this._memNotificationRepository,
  );

  static MemService? _instance;

  factory MemService() => i(
        () => _instance ??= MemService._(
          MemRepository(),
          MemItemRepository(),
          MemNotificationRepository(),
        ),
      );
}
