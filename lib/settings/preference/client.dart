import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/notifications/schedule_client.dart';

import 'keys.dart';
import 'preference.dart';
import 'repository.dart';

class PreferenceClient {
  final PreferenceRepository _repository;
  final NotificationClient _notificationClient;

  PreferenceClient._(
    this._repository,
    this._notificationClient,
  );

  Future<void> updateNotifyAfterInactivity(
    int? secondsOfTime,
  ) =>
      v(
        () async {
          if (secondsOfTime != null) {
            await _repository.receive(
              PreferenceEntity(
                notifyAfterInactivity,
                secondsOfTime,
              ),
            );
          } else {
            await _repository.discard(notifyAfterInactivity);
          }

          await _notificationClient.setNotificationAfterInactivity();
        },
        {
          'secondsOfTime': secondsOfTime,
        },
      );

  static PreferenceClient? _instance;

  factory PreferenceClient({
    PreferenceRepository? repository,
    NotificationClient? notificationClient,
  }) =>
      i(
        () => _instance ??= PreferenceClient._(
          repository ?? PreferenceRepository(),
          notificationClient ?? NotificationClient(),
        ),
        {
          'repository': repository,
          'notificationClient': notificationClient,
        },
      );

  static void resetSingleton() => v(
        () {
          ScheduleClient.resetSingleton();
          _instance = null;
        },
        {
          '_instance': _instance,
        },
      );
}
