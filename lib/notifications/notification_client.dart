import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/act_repository.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/settings/client.dart';
import 'package:mem/settings/keys.dart';
import 'package:mem/values/constants.dart';

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
  final PreferenceClientRepository _preferenceClientRepository;
  final MemRepository _memRepository;
  final MemNotificationRepository _memNotificationRepository;

  NotificationClient._(
    this.notificationChannels,
    this._scheduleClient,
    this._notificationRepository,
    this._preferenceClientRepository,
    this._memRepository,
    this._memNotificationRepository,
  );

  static NotificationClient? _instance;

  factory NotificationClient([BuildContext? context]) => v(
        () => _instance ??= NotificationClient._(
          NotificationChannels(buildL10n(context)),
          ScheduleClient(),
          NotificationRepository(),
          PreferenceClientRepository(),
          MemRepository(),
          MemNotificationRepository(),
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
    int memId,
  ) =>
      v(
        () async {
          final savedMem = await _memRepository
              .ship(id: memId)
              .then((v) => v.singleOrNull?.toV1());

          if (savedMem == null || savedMem.isDone || savedMem.isArchived) {
            await cancelMemNotifications(memId);
            return;
          }

          if (notificationType == NotificationType.repeat) {
            if (!await _shouldNotify(memId)) {
              return;
            }
          }

          if (notificationType == NotificationType.startMem) {
            final latestAct =
                (await ActRepository().ship(memId: memId, latestByMemIds: true))
                    .singleOrNull;
            if (latestAct != null && latestAct.isActive) {
              return;
            }
          }

          await Future.wait(NotificationType.values
              .where(
                (e) => e != NotificationType.activeAct && e != notificationType,
              )
              .map(
                (e) => _notificationRepository
                    .discard(e.buildNotificationId(memId)),
              ));
          if (notificationType == NotificationType.activeAct ||
              notificationType == NotificationType.pausedAct ||
              notificationType == NotificationType.afterActStarted) {
            await _notificationRepository
                .discard(NotificationType.activeAct.buildNotificationId(memId));
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

  Future<void> registerMemNotifications(
    int memId, {
    SavedMemV1? savedMem,
    Iterable<SavedMemNotification>? savedMemNotifications,
  }) =>
      v(
        () async {
          final mem = savedMem ??
              await _memRepository.ship(id: memId).then((v) => v.single.toV1());
          if (mem!.isDone || mem.isArchived) {
            cancelMemNotifications(memId);
          } else {
            final latestAct = await ActRepository()
                .ship(
                  memId: memId,
                  latestByMemIds: true,
                )
                .then((value) => value.singleOrNull);
            final startOfDay =
                (await _preferenceClientRepository.shipByKey(startOfDayKey))
                        .value ??
                    defaultStartOfDay;
            for (var schedule in [
              ...mem.periodSchedules(startOfDay),
              MemNotifications.periodicScheduleOf(
                mem,
                startOfDay,
                savedMemNotifications ??
                    await _memNotificationRepository
                        .ship(memId: memId)
                        .then((value) => value.map((e) => e.toV1())),
                latestAct,
                DateTime.now(),
              )
            ]) {
              await _scheduleClient.receive(schedule);
            }
          }
        },
        {
          "memId": memId,
          "savedMem": savedMem,
          "savedMemNotifications": savedMemNotifications,
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
          final memNotifications = await _memNotificationRepository
              .ship(memId: memId)
              .then((value) => value.map((e) => e.toV1()));
          for (var notification in memNotifications.where((element) =>
              element.isEnabled() && element.isAfterActStarted())) {
            await _scheduleClient.receive(
              Schedule.of(
                memId,
                now.add(Duration(seconds: notification.time!)),
                NotificationType.afterActStarted,
              ),
            );
          }

          await registerMemNotifications(
            memId,
            savedMemNotifications: memNotifications,
          );
        },
        {
          "memId": memId,
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

          await registerMemNotifications(
            memId,
          );
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

  Future<bool> _shouldNotify(int memId) => v(
        () async {
          final savedMemNotifications = await _memNotificationRepository
              .ship(memId: memId)
              .then((value) => value.map((e) => e.toV1()));
          final repeatByDayOfWeekMemNotifications = savedMemNotifications.where(
            (element) => element.isEnabled() && element.isRepeatByDayOfWeek(),
          );

          if (repeatByDayOfWeekMemNotifications.isNotEmpty) {
            final now = DateTime.now();
            if (!repeatByDayOfWeekMemNotifications
                .map((e) => e.time)
                .contains(now.weekday)) {
              return false;
            }
          }

          final repeatByNDayMemNotification =
              savedMemNotifications.singleWhereOrNull(
            (element) => element.isEnabled() && element.isRepeatByNDay(),
          );
          final lastActTime = await ActRepository()
              .ship(memId: memId, latestByMemIds: true)
              .then((value) =>
                  value.singleOrNull?.period.end ??
                  // FIXME 永続化されている時点でstartは必ずあるので型で表現する
                  value.singleOrNull?.period.start!);

          if (lastActTime != null) {
            if (Duration(
                    days:
                        // FIXME 永続化されている時点でtimeは必ずあるので型で表現する
                        //  repeatByNDayMemNotification自体がないのは別の話
                        repeatByNDayMemNotification?.time! ?? 1) >
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
            );
          }
        },
      );
}

const notificationTypeKey = "notificationType";
