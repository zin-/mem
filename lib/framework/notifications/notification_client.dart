import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/today_act_count.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
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
  final ActQueryService _actQueryService;
  final TargetRepository _targetRepository;

  NotificationClient._(
    this.notificationChannels,
    this._scheduleClient,
    this._notificationRepository,
    this._preferenceClientRepository,
    this._memRepository,
    this._memNotificationRepository,
    this._actQueryService,
    this._targetRepository,
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
          ActQueryService(),
          TargetRepository(),
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
            final savedMem = await _memRepository.shipById(memId);

            if (savedMem.toDomain().isDone || savedMem.toDomain().isArchived) {
              await cancelMemNotifications(memId);
              return;
            }

            if (notificationType == NotificationType.repeat) {
              if (!await _shouldNotify(memId)) {
                return;
              }
            }

            if (notificationType == NotificationType.startMem) {
              final latestAct = await _actQueryService
                  .fetchLatestByMemIds(memId)
                  .then((v) => v?.toDomain());
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

  Future<DateTime?> registerMemNotifications(Mem mem) => v(
        () async {
          if (mem.isDone || mem.isArchived) {
            cancelMemNotifications(mem.id!);
            return null;
          } else {
            final latestAct = await _actQueryService
                .fetchLatestByMemIds(mem.id!)
                .then((v) => v?.toDomain());
            final scheduleAnchor =
                await _actQueryService.resolveScheduleAnchorForNotifications(
              memId: mem.id!,
              latestAct: latestAct,
              scheduleAnchorAct: mem.scheduleAnchorAct,
            );
            final startOfDay =
                (await _preferenceClientRepository.shipByKey(startOfDayKey))
                        .value ??
                    defaultStartOfDay;
            final now = DateTime.now();
            final today = await _actQueryService.todayActCount(
              memId: mem.id!,
              period: TodayActCount.period(now, startOfDay),
              targets: _targetRepository,
            );

            final atList = [
              ...mem.periodSchedules(startOfDay),
              MemNotifications.periodicScheduleOf(
                mem,
                startOfDay,
                await _memNotificationRepository
                    .ship(memId: mem.id!)
                    .then((v) => v.map((e) => e.toDomain())),
                latestAct,
                now,
                scheduleAnchor: scheduleAnchor,
                target: today?.target,
                todayCount: today?.value ?? 0,
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
          for (var notification in memNotifications.where((e) =>
              e.toDomain().isEnabled() && e.toDomain().isAfterActStarted())) {
            await _scheduleClient.receive(
              Schedule.of(
                memId,
                now.add(Duration(seconds: notification.toDomain().time!)),
                NotificationType.afterActStarted,
              ),
            );
          }
          final mem =
              await _memRepository.shipById(memId).then((v) => v.toDomain());

          await registerMemNotifications(mem);
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
          final mem =
              await _memRepository.shipById(memId).then((v) => v.toDomain());

          await registerMemNotifications(mem);
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
            final activeActCount = await _actQueryService.activeCount();

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

  Future<bool> _shouldNotify(int memId) => shouldNotifyRepeat(
        memId,
        notifications: _memNotificationRepository,
        acts: _actQueryService,
        targets: _targetRepository,
        preferences: _preferenceClientRepository,
      );

  Future<void> resetAll() => v(
        () async {
          await _notificationRepository.discardAll();

          final allSavedMems = await _memRepository
              .ship(
                archived: false,
                done: false,
              )
              .then((v) => v.map((e) => e.toDomain()));

          for (final mem in allSavedMems) {
            await registerMemNotifications(mem);
          }
        },
      );
}

const notificationTypeKey = "notificationType";

Future<bool> shouldNotifyRepeat(
  int memId, {
  MemNotificationRepository? notifications,
  ActQueryService? acts,
  TargetRepository? targets,
  PreferenceRepository? preferences,
  DateTime? now,
}) =>
    v(
      () async {
        final notificationRepository =
            notifications ?? MemNotificationRepository();
        final actQuery = acts ?? ActQueryService();
        final targetRepository = targets ?? TargetRepository();
        final preferenceRepository = preferences ?? PreferenceRepository();
        final clock = now ?? DateTime.now();

        final savedMemNotifications =
            await notificationRepository.ship(memId: memId);
        final repeatByDayOfWeekMemNotifications = savedMemNotifications.where(
          (e) => e.toDomain().isEnabled() && e.toDomain().isRepeatByDayOfWeek(),
        );

        if (repeatByDayOfWeekMemNotifications.isNotEmpty &&
            !repeatByDayOfWeekMemNotifications
                .map((e) => e.toDomain().time)
                .contains(clock.weekday)) {
          return false;
        }

        final repeatByNDayMemNotification =
            savedMemNotifications.singleWhereOrNull(
          (e) => e.toDomain().isEnabled() && e.toDomain().isRepeatByNDay(),
        );
        final latestAct = await actQuery
            .fetchLatestByMemIds(memId)
            .then((value) => value?.toDomain());
        final scheduleAnchor =
            await actQuery.resolveScheduleAnchorForNotifications(
          memId: memId,
          latestAct: latestAct,
        );
        final lastActTime = scheduleAnchor?.period?.end?.dateTime ??
            scheduleAnchor?.period?.start?.dateTime;
        final startOfDay =
            (await preferenceRepository.shipByKey(startOfDayKey)).value ??
                defaultStartOfDay;
        final today = await actQuery.todayActCount(
          memId: memId,
          period: TodayActCount.period(clock, startOfDay),
          targets: targetRepository,
        );
        final requiredDays = repeatByNDayMemNotification?.toDomain().time! ?? 1;
        final unmetDailyCount = today != null &&
            today.value < today.target.value &&
            requiredDays == 1;

        if (lastActTime != null && !unmetDailyCount) {
          if (Duration(days: requiredDays) > clock.difference(lastActTime)) {
            return false;
          }
        }

        return true;
      },
      {
        'memId': memId,
        'now': now,
      },
    );
