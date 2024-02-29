import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/cancel_notification.dart';
import 'package:mem/notifications/notification/one_time_notification.dart';
import 'package:mem/notifications/notification/repeated_notification.dart';
import 'package:mem/notifications/notification/show_notification.dart';
import 'package:mem/notifications/notification_channels.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/schedule.dart';
import 'package:mem/notifications/schedule_client.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

import 'notification_actions.dart';
import 'notification_repository.dart';

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
              NotificationClientV3().notificationActions.startActAction,
              NotificationClientV3().notificationActions.finishActiveActAction,
            ],
            NotificationClientV3().notificationChannels.repeatedReminderChannel,
          ),
        );
      },
      {
        "id": id,
        "params": params,
      },
    );

// TODO refactor
class NotificationClientV3 {
  final NotificationChannels notificationChannels;
  final NotificationActions notificationActions;

  final ScheduleClient _scheduleClient;
  final NotificationRepository _notificationRepository;

  void registerMemNotifications(
    SavedMem savedMem,
    Iterable<MemNotification>? memNotifications,
  ) =>
      v(
        () {
          _memReminder(savedMem);

          memNotifications?.forEach((e) {
            if (e.isEnabled()) {
              _memRepeatedReminder(savedMem, e);
            } else {
              _memRepeatedReminder(savedMem, null);
            }
          });

          final repeatMemNotification = memNotifications
              ?.whereType<SavedMemNotification>()
              .singleWhereOrNull(
                (element) => element.isRepeated(),
              );
          if (repeatMemNotification != null) {
            _registerMemRepeatNotification(
              savedMem.name,
              repeatMemNotification,
              memNotifications?.singleWhereOrNull(
                (element) => element.isRepeatByNDay(),
              ),
            );
          }
        },
        {
          "savedMem": savedMem,
          "memNotifications": memNotifications,
        },
      );

  void cancelMemNotifications(int memId) => v(
        () {
          CancelAllMemNotifications.of(memId).forEach(
            (cancelNotification) =>
                _notificationRepository.receive(cancelNotification),
          );
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
                OneTimeNotification(
                  afterActStartedNotificationId(memId),
                  memName,
                  notification.message,
                  json.encode({memIdKey: memId}),
                  [
                    notificationActions.finishActiveActAction,
                  ],
                  notificationChannels.afterActStartedNotificationChannel,
                  DateTime.now().add(Duration(seconds: notification.time!)),
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

  Future<void> _memReminder(SavedMem savedMem) => v(
        () async {
          final memNotifications = MemNotifications.of(
            savedMem,
            // TODO 時間がないときのデフォルト値を設定から取得する
            5, 0,
          );

          for (var element in memNotifications) {
            await _notificationRepository.receive(element);
          }
        },
        {
          "savedMem": savedMem,
        },
      );

  // TODO _registerMemRepeatNotificationと統合する
  _memRepeatedReminder(
    SavedMem savedMem,
    MemNotification? memNotification,
  ) =>
      v(
        () async {
          if (memNotification == null) {
            await _notificationRepository.receive(
              CancelNotification(memRepeatedNotificationId(savedMem.id)),
            );
          } else {
            final now = DateTime.now();
            final hours = (memNotification.time! / 60 / 60).floor();
            final minutes =
                ((memNotification.time! - hours * 60 * 60) / 60).floor();
            final seconds =
                ((memNotification.time! - ((hours * 60) + minutes) * 60) / 60)
                    .floor();
            var notifyFirstAt = DateTime(
              now.year,
              now.month,
              now.day,
              hours,
              minutes,
              seconds,
            );
            if (notifyFirstAt.isBefore(now)) {
              notifyFirstAt = notifyFirstAt.add(const Duration(days: 1));
            }

            final repeatedNotification = RepeatedNotification(
              memRepeatedNotificationId(savedMem.id),
              savedMem.name,
              memNotification.message,
              json.encode({memIdKey: memNotification.memId}),
              [
                notificationActions.startActAction,
                notificationActions.finishActiveActAction,
              ],
              notificationChannels.repeatedReminderChannel,
              notifyFirstAt,
              NotificationInterval.perDay,
            );

            await _notificationRepository.receive(repeatedNotification);
          }
        },
        {
          "savedMem": savedMem,
          "memNotification": memNotification,
        },
      );

  Future<void> _registerMemRepeatNotification(
    String memName,
    SavedMemNotification repeatMemNotification,
    MemNotification? repeatEveryNDay,
  ) =>
      v(
        () async {
          final now = DateTime.now();
          final hours = (repeatMemNotification.time! / 60 / 60).floor();
          final minutes =
              ((repeatMemNotification.time! - hours * 60 * 60) / 60).floor();
          final seconds =
              ((repeatMemNotification.time! - ((hours * 60) + minutes) * 60) /
                      60)
                  .floor();
          var notifyFirstAt = DateTime(
            now.year,
            now.month,
            now.day,
            hours,
            minutes,
            seconds,
          );
          if (notifyFirstAt.isBefore(now)) {
            notifyFirstAt = notifyFirstAt.add(const Duration(days: 1));
          }

          final intervalDays = repeatEveryNDay?.time;
          if (intervalDays != null) {
            await _scheduleClient.receive(
              Schedule(
                memRepeatedNotificationId(repeatMemNotification.memId),
                notifyFirstAt,
                Duration(
                  days: intervalDays,
                ),
                showRepeatEveryNDayNotification,
                {
                  memIdKey: repeatMemNotification.memId,
                },
              ),
            );
          }
        },
        {
          "memName": memName,
          "repeatMemNotification": repeatMemNotification,
        },
      );

  NotificationClientV3._(
    this.notificationChannels,
    this.notificationActions,
    this._scheduleClient,
    this._notificationRepository,
  );

  static NotificationClientV3? _instance;

  factory NotificationClientV3([BuildContext? context]) => v(
        () {
          final l10n = buildL10n(context);
          return _instance ??= NotificationClientV3._(
            NotificationChannels(l10n),
            NotificationActions(l10n),
            ScheduleClient(),
            NotificationRepository(),
          );
        },
        {
          "context": context,
        },
      );
}
