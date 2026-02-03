import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/repository.dart';

import 'mem_notifications.dart';
import 'notification/type.dart';
import 'notification_channels.dart';
import 'notification_ids.dart';
import 'notification_repository.dart';
import 'schedule.dart';
import 'schedule_client.dart';

class NotificationClient {
  final NotificationChannels notificationChannels;

  final ScheduleClient _scheduleClient;
  final NotificationRepository _notificationRepository;
  final PreferenceRepository _preferenceClientRepository;
  final MemRepository _memRepository;
  final MemNotificationRepository _memNotificationRepository;
  final ActRepository _actRepository;

  NotificationClient._(
    this.notificationChannels,
    this._scheduleClient,
    this._notificationRepository,
    this._preferenceClientRepository,
    this._memRepository,
    this._memNotificationRepository,
    this._actRepository,
  );

  static NotificationClient? _instance;

  factory NotificationClient([BuildContext? context]) => v(
        () => _instance ??= NotificationClient._(
          NotificationChannels(buildL10n(context)),
          ScheduleClient(),
          NotificationRepository(),
          PreferenceRepository(),
          MemRepository(),
          MemNotificationRepository(),
          ActRepository(),
        ),
        {
          'context': context,
          '_instance': _instance,
        },
      );

  static void resetSingleton() => v(
        () {
          ScheduleClient.resetSingleton();
          NotificationRepository.reset();
          _instance = null;
        },
        {
          '_instance': _instance,
        },
      );

  Future<void> show(
    NotificationType notificationType,
    int? memId,
  ) =>
      v(
        () async {
          if (memId != null) {
            final savedMem = await _memRepository
                .ship(id: memId)
                .then((v) => v.singleOrNull);

            if (savedMem == null ||
                savedMem.value.isDone ||
                savedMem.value.isArchived) {
              await cancelMemNotifications(memId);
              return;
            }

            if (notificationType == NotificationType.repeat) {
              if (!await _shouldNotify(memId)) {
                return;
              }
            }

            if (notificationType == NotificationType.startMem) {
              final latestAct = await ActRepository()
                  .ship(memId: memId, latestByMemIds: true)
                  .then(
                    (v) => v.singleOrNull?.value,
                  );
              if (latestAct != null && latestAct.isActive) {
                return;
              }
            }

            await Future.wait(NotificationType.values
                .where(
                  (e) =>
                      e != NotificationType.activeAct &&
                      e != NotificationType.notifyAfterInactivity &&
                      e != notificationType,
                )
                .map(
                  (e) => _notificationRepository
                      .discard(e.buildNotificationId(memId)),
                ));
            if (notificationType == NotificationType.activeAct ||
                notificationType == NotificationType.pausedAct ||
                notificationType == NotificationType.afterActStarted) {
              await _notificationRepository.discard(
                  NotificationType.activeAct.buildNotificationId(memId));
            }
          }

          await _notificationRepository.receive(
            await notificationChannels.buildNotification(
              notificationType,
              memId,
            ),
          );
        },
        {
          'notificationType': notificationType,
          'memId': memId,
        },
      );

  Future<DateTime?> registerMemNotifications(
    int memId, {
    SavedMemEntityV1? savedMem,
    Iterable<SavedMemNotificationEntity>? savedMemNotifications,
    Mem? mem,
  }) =>
      v(
        () async {
          final memEntityV1 = savedMem ??
              await _memRepository
                  .ship(
                    id: memId,
                  )
                  .then(
                    (v) => v.single,
                  );
          final memV2 = memEntityV1?.value ?? mem;

          if (memV2!.isDone || memV2.isArchived) {
            cancelMemNotifications(memId);
            return null;
          } else {
            final latestAct = await ActRepository()
                .ship(
                  memId: memId,
                  latestByMemIds: true,
                )
                .then(
                  (v) => v.singleOrNull?.value,
                );
            final startOfDay =
                (await _preferenceClientRepository.shipByKey(startOfDayKey))
                        .value ??
                    defaultStartOfDay;

            final atList = [
              ...memV2.periodSchedules(startOfDay),
              MemNotifications.periodicScheduleOf(
                memV2,
                startOfDay,
                (savedMemNotifications ??
                        await _memNotificationRepository.ship(memId: memId))
                    .map((e) => e.value),
                latestAct,
                DateTime.now(),
              )
            ].map((e) {
              _scheduleClient.receive(e);
              return e is TimedSchedule ? e.startAt : null;
            });

            return atList
                .whereType<DateTime>()
                .sorted((a, b) => a.compareTo(b))
                .firstOrNull;
          }
        },
        {
          "memId": memId,
          "savedMem": savedMem,
          "savedMemNotifications": savedMemNotifications,
          "mem": mem,
        },
      );

  Future<void> cancelMemNotifications(int memId) => v(
        () async {
          for (var id in AllMemNotificationsId.of(memId)) {
            await _notificationRepository.discard(id);
            await _scheduleClient.discard(id);
          }
        },
        {
          "memId": memId,
        },
      );

  Future<void> startActNotifications(
    int memId,
  ) =>
      v(
        () async {
          await cancelActNotification(memId);

          await show(
            NotificationType.activeAct,
            memId,
          );

          final now = DateTime.now();
          final memNotifications =
              await _memNotificationRepository.ship(memId: memId);
          for (var notification in memNotifications.where(
              (e) => e.value.isEnabled() && e.value.isAfterActStarted())) {
            await _scheduleClient.receive(
              Schedule.of(
                memId,
                now.add(Duration(seconds: notification.value.time!)),
                NotificationType.afterActStarted,
              ),
            );
          }
          final mem = await _memRepository
              .ship(id: memId)
              .then((v) => v.singleOrNull?.value);

          await registerMemNotifications(
            memId,
            savedMemNotifications: memNotifications,
            mem: mem,
          );
          await setNotificationAfterInactivity();
        },
        {
          'memId': memId,
        },
      );

  Future<void> pauseActNotification(
    int memId,
  ) =>
      v(
        () async {
          await cancelActNotification(memId);

          await show(
            NotificationType.pausedAct,
            memId,
          );
          final mem = await _memRepository
              .ship(id: memId)
              .then((v) => v.singleOrNull?.value);

          await registerMemNotifications(
            memId,
            mem: mem,
          );
          await setNotificationAfterInactivity();
        },
        {
          "memId": memId,
        },
      );

  Future<void> cancelActNotification(int memId) => v(
        () async {
          await _notificationRepository.discard(activeActNotificationId(memId));

          await _notificationRepository
              .discard(afterActStartedNotificationId(memId));
          await _scheduleClient.discard(afterActStartedNotificationId(memId));
        },
        {
          "memId": memId,
        },
      );

  Future<void> setNotificationAfterInactivity() => v(
        () async {
          final timeOfSeconds = await PreferenceRepository()
              .shipByKey(notifyAfterInactivity)
              .then((v) => v.value);

          if (timeOfSeconds != null) {
            final activeActCount = await _actRepository.count(isActive: true);

            if (activeActCount == 0) {
              await _scheduleClient.receive(
                Schedule.of(
                  null,
                  DateTime.now().add(
                    Duration(
                      seconds: timeOfSeconds,
                    ),
                  ),
                  NotificationType.notifyAfterInactivity,
                ),
              );
              return;
            }
          }

          await _scheduleClient.discard(
            NotificationType.notifyAfterInactivity.buildNotificationId(),
          );
        },
      );

  Future<bool> _shouldNotify(int memId) => v(
        () async {
          final savedMemNotifications =
              await _memNotificationRepository.ship(memId: memId);
          final repeatByDayOfWeekMemNotifications = savedMemNotifications.where(
            (e) => e.value.isEnabled() && e.value.isRepeatByDayOfWeek(),
          );

          if (repeatByDayOfWeekMemNotifications.isNotEmpty) {
            final now = DateTime.now();
            if (!repeatByDayOfWeekMemNotifications
                .map((e) => e.value.time)
                .contains(now.weekday)) {
              return false;
            }
          }

          final repeatByNDayMemNotification =
              savedMemNotifications.singleWhereOrNull(
            (e) => e.value.isEnabled() && e.value.isRepeatByNDay(),
          );
          final lastActTime = await ActRepository()
              .ship(memId: memId, latestByMemIds: true)
              .then((v) =>
                  v.singleOrNull?.value.period?.end ??
                  v.singleOrNull?.value.period?.start!);

          if (lastActTime != null) {
            if (Duration(
                    days:
                        // FIXME 永続化されている時点でtimeは必ずあるので型で表現する
                        //  repeatByNDayMemNotification自体がないのは別の話
                        repeatByNDayMemNotification?.value.time! ?? 1) >
                DateTime.now().difference(lastActTime)) {
              return false;
            }
          }

          return true;
        },
      );

  Future<void> resetAll() => v(
        () async {
          await _notificationRepository.discardAll();

          final allSavedMems = await _memRepository.ship(
            archived: false,
            done: false,
          );

          for (final mem in allSavedMems) {
            await registerMemNotifications(
              mem.id,
              mem: mem.value,
            );
          }
        },
      );
}

const notificationTypeKey = "notificationType";
