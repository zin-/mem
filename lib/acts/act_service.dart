import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

class ActService {
  final ActRepository _actRepository;

  // final NotificationService _notificationService;

  Future<Act> startBy(int memId) => i(
        () async {
          final received = await _actRepository.receive(Act(
            memId,
            DateAndTimePeriod.startNow(),
          ));

          // TODO 開始したときに、通知を表示する

          return received;
        },
        memId,
      );

  ActService._(
    this._actRepository,
    // this._notificationService,
  );

  static ActService? _instance;

  factory ActService() => _instance ??= _instance = ActService._(
        ActRepository(),
        // NotificationService(),
      );
}
