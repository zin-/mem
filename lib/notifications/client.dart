import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification.dart';
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
  final PreferenceClient _preferenceClient;

  NotificationClient._(
    this.notificationChannels,
    this._scheduleClient,
    this._notificationRepository,
    this._preferenceClient,
  );

  static NotificationClient? _instance;

  factory NotificationClient([BuildContext? context]) => v(
        () {
          final l10n = buildL10n(context);
          return _instance ??= NotificationClient._(
            NotificationChannels(l10n),
            ScheduleClient(),
            NotificationRepository(),
            PreferenceClient(),
          );
        },
        {
          "context": context,
        },
      );

  Future<void> show(
    NotificationType notificationType,
    int memId,
  ) =>
      v(
        () async => await _notificationRepository.receive(
          await notificationChannels.buildNotification(
            notificationType,
            memId,
          ),
        ),
        {
          "notificationType": notificationType,
          "memId": memId,
        },
      );

  Future<void> registerMemNotifications(
    SavedMem savedMem,
    // FIXME Iterable<SavedMemNotification>が正しい
    //  影響箇所が大きいため保留
    List<MemNotification>? memNotifications,
  ) =>
      v(
        () async {
          if (savedMem.isDone || savedMem.isArchived) {
            cancelMemNotifications(savedMem.id);
          } else {
            for (var schedule in MemNotifications.scheduleOf(
              savedMem,
              (await _preferenceClient.shipByKey(startOfDayKey)).value ??
                  defaultStartOfDay,
              memNotifications,
              scheduleCallback,
            )) {
              await _scheduleClient.receive(schedule);
            }
          }
        },
        {
          "savedMem": savedMem,
          "memNotifications": memNotifications,
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
    Iterable<SavedMemNotification> savedMemNotifications,
  ) =>
      v(
        () async {
          await cancelActNotification(memId);

          await show(
            NotificationType.activeAct,
            memId,
          );

          final now = DateTime.now();
          for (var notification in savedMemNotifications.where((element) =>
              element.isEnabled() && element.isAfterActStarted())) {
            await _scheduleClient.receive(TimedSchedule(
              afterActStartedNotificationId(memId),
              now.add(Duration(seconds: notification.time!)),
              scheduleCallback,
              {
                memIdKey: notification.memId,
                notificationTypeKey: NotificationType.afterActStarted.name,
              },
            ));
          }
        },
        {
          "memId": memId,
          "savedMemNotifications": savedMemNotifications,
        },
      );

  Future<void> pauseActNotification(
    int memId,
    DateAndTime when,
  ) =>
      v(
        () async {
          await cancelActNotification(memId);

          await show(
            NotificationType.pausedAct,
            memId,
          );
        },
        {
          "memId": memId,
          "when": when,
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
}

const notificationTypeKey = "notificationType";

Future<void> scheduleCallback(int id, Map<String, dynamic> params) => i(
      () async {
        await openDatabase();

        final memId = params[memIdKey] as int;

        final notificationType = NotificationType.values.singleWhere(
          (element) => element.name == params[notificationTypeKey],
        );

        await NotificationClient().show(
          notificationType,
          memId,
        );
      },
      {"id": id, "params": params},
    );
