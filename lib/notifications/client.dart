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
import 'notification/show_notification.dart';
import 'notification/type.dart';
import 'notification_actions.dart';
import 'notification_channels.dart';
import 'notification_ids.dart';
import 'notification_repository.dart';
import 'schedule_client.dart';

@pragma('vm:entry-point')
Future<void> showRepeatEveryNDayNotification(
  int id,
  Map<String, dynamic> params,
) =>
    v(
      () async {
        await openDatabase();

        final memId = params[memIdKey];
        final mem = await MemRepository().shipById(memId);
        final memNotification =
            (await MemNotificationRepository().shipByMemId(mem.id)).singleWhere(
          (element) => element.isRepeated(),
        );

        await NotificationRepository().receive(
          ShowNotification(
            memRepeatedNotificationId(mem.id),
            mem.name,
            memNotification.message,
            json.encode(params),
            [
              NotificationClient().notificationActions.startActAction,
              NotificationClient().notificationActions.finishActiveActAction,
            ],
            NotificationClient().notificationChannels.repeatedReminderChannel,
          ),
        );
      },
      {
        "id": id,
        "params": params,
      },
    );

// TODO refactor
class NotificationClient {
  final NotificationChannels notificationChannels;
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
          await _notificationRepository.receive(
            ShowNotification(
              id,
              title,
              body,
              jsonEncode(params),
              [
                notificationActions.doneMemAction,
                notificationActions.startActAction,
                notificationActions.finishActiveActAction,
              ],
              notificationChannels.reminderChannel,
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
          // TODO 混乱し始めたので整理する
          //  SavedMemから通知を登録する
          //    SavedMemNotificationsからも登録する
          //      これはSavedMemの状態によって登録するのか削除するのか変わるため
          //    SavedMemが完了もしくはアーカイブされている場合、すべてキャンセルする
          //      削除した場合も同様にキャンセルするため、関数に切り出す
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
    Iterable<SavedMemNotification> afterActStartedNotifications,
  ) =>
      v(
        () async {
          _notificationRepository.receive(
            ShowNotification(
              activeActNotificationId(memId),
              memName,
              'Running',
              json.encode({memIdKey: memId}),
              [
                notificationActions.finishActiveActAction,
                notificationActions.pauseAct,
              ],
              notificationChannels.activeActNotificationChannel,
            ),
          );

          if (afterActStartedNotifications.isNotEmpty) {
            for (var notification in afterActStartedNotifications) {
              _notificationRepository.receive(
                ShowNotification(
                  afterActStartedNotificationId(memId),
                  memName,
                  notification.message,
                  json.encode({memIdKey: memId}),
                  [
                    notificationActions.finishActiveActAction,
                  ],
                  notificationChannels.afterActStartedNotificationChannel,
                ),
              );
            }
          }
        },
        {
          "memId": memId,
          "memName": memName,
          "afterActStartedNotifications": afterActStartedNotifications,
        },
      );

  Future<void> pauseActNotification(
    int memId,
    String memName,
    DateAndTime when,
  ) =>
      v(
        () async {
          await _notificationRepository.receive(
            ShowNotification(
              pausedActNotificationId(memId),
              memName,
              "Paused",
              json.encode({memIdKey: memId}),
              [
                notificationActions.startActAction,
              ],
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
            final memRepeatNotification =
                ((await MemNotificationRepository().shipByMemId(memId)))
                    .where((element) => element.isRepeated());
            // FIXME lastじゃなくてsingleのはず
            //  保存側のバグなので一旦このままコミットする
            body = memRepeatNotification.last.message;
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
