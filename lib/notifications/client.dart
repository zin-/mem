import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/action.dart';
import 'package:mem/notifications/notification/channel.dart';
import 'package:mem/notifications/notification/done_mem_notification_action.dart';
import 'package:mem/notifications/notification/finish_active_act_notification_action.dart';
import 'package:mem/notifications/notification/pause_act_notification_action.dart';
import 'package:mem/notifications/notification/repeated_notification.dart';
import 'package:mem/notifications/notification/show_notification.dart';
import 'package:mem/notifications/notification/start_act_notification_action.dart';
import 'package:mem/notifications/notification_channels.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/notification_service.dart';
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
              NotificationClientV3()._notificationActions.startActAction,
              NotificationClientV3()._notificationActions.finishActiveActAction,
            ],
            NotificationClientV3()
                ._notificationChannels
                .repeatedReminderChannel,
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
  final NotificationChannels _notificationChannels;
  final NotificationActions _notificationActions;

  @Deprecated("use NotificationRepository")
  final NotificationService _notificationService;
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
              _notificationService.memRepeatedReminder(savedMem, e);
            } else {
              _notificationService.memRepeatedReminder(savedMem, null);
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

          await _notificationRepository.receiveV2(
            RepeatedNotification(
              memRepeatedNotificationId(repeatMemNotification.memId),
              memName,
              repeatMemNotification.message,
              json.encode({memIdKey: repeatMemNotification.memId}),
              [
                _notificationActions.startActAction,
                _notificationActions.finishActiveActAction,
              ],
              _notificationChannels.repeatedReminderChannel,
              notifyFirstAt,
              NotificationInterval.perDay,
              intervalSeconds: repeatEveryNDay?.time == null
                  ? null
                  : repeatEveryNDay!.time! * 60 * 60 * 24,
            ),
            showRepeatEveryNDayNotification,
          );
        },
        {
          "memName": memName,
          "repeatMemNotification": repeatMemNotification,
        },
      );

  NotificationClientV3._(
    this._notificationChannels,
    this._notificationActions,
    this._notificationService,
    this._notificationRepository,
  );

  static NotificationClientV3? _instance;

  factory NotificationClientV3([BuildContext? context]) => v(
        () {
          final l10n = buildL10n(context);
          return _instance ??= NotificationClientV3._(
            NotificationChannels(l10n),
            NotificationActions(l10n),
            NotificationService(),
            NotificationRepository(),
          );
        },
        {
          "context": context,
        },
      );
}

class NotificationClientV2 {
  late final NotificationChannel reminderChannel;
  late final NotificationChannel repeatedReminderChannel;
  late final NotificationChannel activeActNotificationChannel;
  late final NotificationChannel pausedAct;
  late final NotificationChannel afterActStartedNotificationChannel;

  late final NotificationAction doneMemAction;
  late final NotificationAction startActAction;
  late final NotificationAction finishActiveActAction;
  late final NotificationAction pauseAct;

  final notificationActions = <NotificationAction>[];

  NotificationClientV2._(AppLocalizations l10n) {
    reminderChannel = NotificationChannel(
      'reminder',
      l10n.reminderName,
      l10n.reminderDescription,
    );
    repeatedReminderChannel = NotificationChannel(
      'repeated-reminder',
      l10n.repeatedReminderName,
      l10n.repeatedReminderDescription,
    );
    activeActNotificationChannel = NotificationChannel(
      'active_act-notification',
      l10n.activeActNotification,
      l10n.activeActNotificationDescription,
      usesChronometer: true,
      ongoing: true,
      autoCancel: false,
    );
    pausedAct = NotificationChannel(
      "paused_act",
      l10n.pausedActNotification,
      l10n.pausedActNotificationDescription,
      usesChronometer: true,
      autoCancel: false,
    );
    afterActStartedNotificationChannel = NotificationChannel(
      'after_act_started-notification',
      l10n.afterActStartedNotification,
      l10n.afterActStartedNotificationDescription,
      usesChronometer: true,
      autoCancel: false,
    );

    notificationActions.addAll([
      doneMemAction = DoneMemNotificationAction('done-mem', l10n.doneLabel),
      startActAction = StartActNotificationAction('start-act', l10n.startLabel),
      finishActiveActAction = FinishActiveActNotificationAction(
        'finish-active_act',
        l10n.finishLabel,
      ),
      pauseAct = PauseActNotificationAction('pause-act', l10n.pauseActLabel),
    ]);
  }

  static NotificationClientV2? _instance;

  factory NotificationClientV2([BuildContext? context]) => v(
        () => _instance ??= NotificationClientV2._(buildL10n(context)),
        {
          "context": context,
        },
      );
}
