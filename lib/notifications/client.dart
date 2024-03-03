import 'dart:convert';

import 'package:collection/collection.dart';
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
import 'notification/cancel_notification.dart';
import 'notification/show_notification.dart';
import 'notification/type.dart';
import 'notification_actions.dart';
import 'notification_channels.dart';
import 'notification_ids.dart';
import 'notification_repository.dart';
import 'schedule.dart';
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
    NotificationType notificationType,
    Map<String, dynamic> params,
  ) =>
      v(
        () async {
          String body;
          switch (notificationType) {
            case NotificationType.startMem:
              body = _startMemNotificationBody;
              break;
            case NotificationType.endMem:
              body = _endMemNotificationBody;
              break;
          }

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
          "notificationType": notificationType,
          "params": params,
        },
      );

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

  Future<void> _memReminder(
    SavedMem savedMem,
  ) =>
      v(
        () async {
          if (savedMem.isDone || savedMem.isArchived) {
            CancelAllMemNotifications.of(savedMem.id).forEach((element) {
              _notificationRepository.discard(element.id);
              _scheduleClient.discard(element.id);
            });
          } else {
            final startId = memStartNotificationId(savedMem.id);
            final endId = memEndNotificationId(savedMem.id);

            await _notificationRepository.discard(startId);
            await _scheduleClient.discard(startId);
            await _notificationRepository.discard(endId);
            await _scheduleClient.discard(endId);

            final period = savedMem.period;
            if (period != null) {
              final startOfDay =
                  (await _preferenceClient.shipByKey(startOfDayKey)).value ??
                      // FIXME どっかで持っておくべきか？
                      const TimeOfDay(hour: 0, minute: 0);

              final start = period.start;
              if (start != null) {
                await _scheduleClient.receive(Schedule(
                  memStartNotificationId(savedMem.id),
                  start.isAllDay
                      ? DateTime(
                          start.year,
                          start.month,
                          start.day,
                          startOfDay.hour,
                          startOfDay.minute,
                        )
                      : start,
                  scheduleCallback,
                  {
                    memIdKey: savedMem.id,
                    notificationTypeKey: NotificationType.startMem.name,
                  },
                ));
              }

              final end = period.end;
              if (end != null) {
                final endOfDay = startOfDay.subtractMinutes(1);

                await _scheduleClient.receive(Schedule(
                  memEndNotificationId(savedMem.id),
                  end.isAllDay
                      ? DateTime(
                          end.year,
                          end.month,
                          // FIXME ここなんか違う気がする
                          startOfDay.compareTo(endOfDay) > 0 &&
                                  start?.day == end.day
                              ? end.day
                              : end.day + 1,
                          endOfDay.hour,
                          endOfDay.minute,
                        )
                      : end,
                  scheduleCallback,
                  {
                    memIdKey: savedMem.id,
                    notificationTypeKey: NotificationType.endMem.name,
                  },
                ));
              }
            }
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

            final repeatedNotification = ShowNotification(
              memRepeatedNotificationId(savedMem.id),
              savedMem.name,
              memNotification.message,
              json.encode({memIdKey: memNotification.memId}),
              [
                notificationActions.startActAction,
                notificationActions.finishActiveActAction,
              ],
              notificationChannels.repeatedReminderChannel,
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
              PeriodicSchedule(
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
}

const notificationTypeKey = "notificationType";
const _startMemNotificationBody = "start";
const _endMemNotificationBody = "end";

Future<void> scheduleCallback(
  int id,
  Map<String, dynamic> params,
) =>
    v(
      () async {
        await openDatabase();

        final memId = params[memIdKey] as int;
        final mem = await MemRepository().shipById(memId);

        final notificationType = NotificationType.values.singleWhere(
          (element) => element.name == params[notificationTypeKey],
        );

        await NotificationClient().show(
          id,
          mem.name,
          notificationType,
          params,
        );
      },
      {
        "id": id,
        "params": params,
      },
    );

extension on TimeOfDay {
  TimeOfDay subtractMinutes(int minutes) {
    int subtracted = (_totalMinutes - minutes + 24 * 60) % (24 * 60);
    return TimeOfDay(hour: subtracted ~/ 60, minute: subtracted % 60);
  }

  int compareTo(TimeOfDay other) =>
      _totalMinutes.compareTo(other._totalMinutes);

  int get _totalMinutes => hour * 60 + minute;
}
