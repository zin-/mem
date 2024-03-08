import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/settings/client.dart';
import 'package:mem/settings/keys.dart';

import 'mem_notifications.dart';
import 'notification/channel.dart';
import 'notification/show_notification.dart';
import 'notification/type.dart';
import 'notification_actions.dart';
import 'notification_channels.dart';
import 'notification_ids.dart';
import 'notification_repository.dart';
import 'schedule.dart';
import 'schedule_client.dart';

// TODO refactor
class NotificationClient {
  // TODO NotificationTypeとも統一できるはず
  //  startとendが同じChannelか
  // TODO idの生成も最後のタイミングでやるならChannelに持たせることができるようになるかも？
  final NotificationChannels notificationChannels;

  // TODO drop
  //  ChannelにActionを持たせる
  //  ChannelごとにActionは決まる
  final NotificationActions notificationActions;

  final ScheduleClient _scheduleClient;
  final NotificationRepository _notificationRepository;
  final PreferenceClient _preferenceClient;

  NotificationClient._(
    this.notificationChannels,
    this.notificationActions,
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
            NotificationActions(l10n),
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
    int id,
    String title,
    String body,
    NotificationType notificationType,
    Map<String, dynamic> params,
  ) =>
      v(
        () async {
          late final NotificationChannel channel;
          switch (notificationType) {
            case NotificationType.startMem:
            case NotificationType.endMem:
              channel = notificationChannels.reminderChannel;
              break;
            case NotificationType.repeat:
              channel = notificationChannels.repeatedReminderChannel;
              break;
            case NotificationType.afterActStarted:
              channel = notificationChannels.afterActStartedNotificationChannel;
              break;
          }

          await _notificationRepository.receive(
            ShowNotification(
              id,
              title,
              body,
              jsonEncode(params),
              channel,
            ),
          );
        },
        {
          "id": id,
          "title": title,
          "body": body,
          "notificationType": notificationType,
          "params": params,
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
                  // FIXME どっかで持っておくべきか？
                  const TimeOfDay(hour: 0, minute: 0),
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
    String memName,
    Iterable<SavedMemNotification> savedMemNotifications,
  ) =>
      v(
        () async {
          await cancelActNotification(memId);
          _notificationRepository.receive(
            ShowNotification(
              activeActNotificationId(memId),
              memName,
              'Running',
              json.encode({memIdKey: memId}),
              notificationChannels.activeActNotificationChannel,
            ),
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
          "memName": memName,
          "savedMemNotifications": savedMemNotifications,
        },
      );

  Future<void> pauseActNotification(
    int memId,
    String memName,
    DateAndTime when,
  ) =>
      v(
        () async {
          await cancelActNotification(memId);
          await _notificationRepository.receive(
            ShowNotification(
              pausedActNotificationId(memId),
              memName,
              "Paused",
              json.encode({memIdKey: memId}),
              notificationChannels.pausedAct,
            ),
          );
        },
        {
          "memId": memId,
          "memName": memName,
          "when": when,
        },
      );

  Future<void> cancelActNotification(int memId) => v(
        () async {
          await _notificationRepository.discard(activeActNotificationId(memId));
          await _notificationRepository
              .discard(afterActStartedNotificationId(memId));
        },
        {
          "memId": memId,
        },
      );
}

const notificationTypeKey = "notificationType";
const _startMemNotificationBody = "start";
const _endMemNotificationBody = "end";

Future<void> scheduleCallback(
  int id,
  Map<String, dynamic> params,
) =>
    i(
      () async {
        await openDatabase();

        final memId = params[memIdKey] as int;
        final mem = await MemRepository().shipById(memId);

        final notificationType = NotificationType.values.singleWhere(
          (element) => element.name == params[notificationTypeKey],
        );

        String body;
        switch (notificationType) {
          case NotificationType.startMem:
            body = _startMemNotificationBody;
            break;
          case NotificationType.endMem:
            body = _endMemNotificationBody;
            break;
          case NotificationType.repeat:
            body = ((await MemNotificationRepository().shipByMemId(memId)))
                .singleWhere((element) => element.isRepeated())
                .message;
            break;
          case NotificationType.afterActStarted:
            body = ((await MemNotificationRepository().shipByMemId(memId)))
                .singleWhere((element) => element.isAfterActStarted())
                .message;
            break;
        }

        await NotificationClient().show(
          id,
          mem.name,
          body,
          notificationType,
          params,
        );
      },
      {
        "id": id,
        "params": params,
      },
    );
