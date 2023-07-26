import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository_v3.dart';
import 'package:mem/logger/log_service.dart';
import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart';

import 'icons.dart';
import 'mem_notifications.dart';
import 'notification/cancel_notification.dart';
import 'notification/notification.dart';
import 'notification/one_time_notification.dart';
import 'notification/repeated_notification.dart';
import 'notification/show_notification.dart';
import 'wrapper.dart';

class NotificationRepository extends RepositoryV3<Notification, Future<void>> {
  final NotificationsWrapper? _flutterLocalNotificationsWrapper;

  Future<void> initialize(
    OnNotificationActionTappedCallback notificationActionHandler,
    Function(int memId)? showMemDetailPage,
  ) =>
      v(
        () async {
          if (defaultTargetPlatform == TargetPlatform.android) {
            // ISSUE #225
// coverage:ignore-start
            showMemDetailPageHandler(Map<dynamic, dynamic> payload) {
              if (showMemDetailPage != null && payload.containsKey(memIdKey)) {
                final memId = payload[memIdKey];
                if (memId is int) {
                  showMemDetailPage(memId);
                }
              }
            }
// coverage:ignore-end

            initializeTimeZones();

            final initialized =
                await _flutterLocalNotificationsWrapper?.initialize(
              androidDefaultIconPath,
              // ISSUE #225
// coverage:ignore-start
              (notificationId, payload) => showMemDetailPageHandler(payload),
// coverage:ignore-end
              notificationActionHandler,
            );

            if (initialized ?? false) {
              await _flutterLocalNotificationsWrapper
                  ?.receiveOnLaunchAppNotification(
                // ISSUE #225
// coverage:ignore-start
                (notificationId, payload) => showMemDetailPageHandler(payload),
// coverage:ignore-end
              );
            }
          }
        },
      );

  @override
  Future<void> receive(
    Notification payload,
  ) =>
      v(
        () async {
          if (payload is RepeatedNotification) {
            await _flutterLocalNotificationsWrapper?.zonedSchedule(
              payload.id,
              payload.title,
              payload.body,
              TZDateTime.from(payload.notifyFirstAt, local),
              payload.payloadJson,
              payload.actions,
              payload.channel,
              payload.interval,
            );
          } else if (payload is OneTimeNotification) {
            await _flutterLocalNotificationsWrapper?.zonedSchedule(
              payload.id,
              payload.title,
              payload.body,
              TZDateTime.from(payload.notifyAt, local),
              payload.payloadJson,
              payload.actions,
              payload.channel,
            );
          } else if (payload is ShowNotification) {
            await _flutterLocalNotificationsWrapper?.show(
              payload.id,
              payload.title,
              payload.body,
              payload.actions,
              payload.channel,
              payload.payloadJson,
            );
          } else if (payload is CancelNotification) {
            await discard(payload.id);
          }
        },
        payload,
      );

  Future<void> discard(int id) => v(
        () async => _flutterLocalNotificationsWrapper?.cancel(id),
        id,
      );

  NotificationRepository._(this._flutterLocalNotificationsWrapper);

  static NotificationRepository? _instance;

  factory NotificationRepository() =>
      _instance ??= _instance = NotificationRepository._(
        defaultTargetPlatform == TargetPlatform.android
            ? NotificationsWrapper()
            : null,
      );

  static void reset(NotificationRepository? notificationRepository) {
    _instance = notificationRepository;
  }
}
