import 'package:mem/acts/act_repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/schedule_client.dart';

import 'keys.dart';
import 'preference.dart';
import 'repository.dart';

class PreferenceClient {
  final PreferenceRepository _repository;
  final ActRepository _actRepository;
  final ScheduleClient _scheduleClient;

  PreferenceClient._(
    this._repository,
    this._actRepository,
    this._scheduleClient,
  );

  Future updateNotifyAfterInactivity(
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

            final activeActCount = await _actRepository.count(isActive: true);
            if (activeActCount == 0) {
              // 現座時刻から指定時間後に
              // TODO 通知されるように設定する
              // await
              info(_scheduleClient.receive);
              //     (
              // TimedSchedule(
              //   0,
              info(DateTime.now().add(Duration(seconds: secondsOfTime)))
                  //   ,
                  //   {},
                  // )
                  // )
                  ;
              return;
            }
          }

          await _repository.discard(notifyAfterInactivity);
          // TODO 通知をキャンセルする
          info(_scheduleClient.discard);
        },
        {
          'secondsOfTime': secondsOfTime,
        },
      );

  static PreferenceClient? _instance;

  factory PreferenceClient({
    PreferenceRepository? repository,
    ActRepository? actRepository,
    ScheduleClient? scheduleClient,
  }) =>
      i(
        () => _instance ??= PreferenceClient._(
          repository ?? PreferenceRepository(),
          actRepository ?? ActRepository(),
          scheduleClient ?? ScheduleClient(),
        ),
        {
          'repository': repository,
          'actRepository': actRepository,
          'scheduleClient': scheduleClient,
        },
      );
}
