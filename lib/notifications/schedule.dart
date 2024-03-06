import 'package:mem/framework/repository/entity.dart';

abstract class Schedule extends Entity {
  final int id;

  Schedule(this.id);
}

class TimedSchedule extends Schedule {
  final DateTime startAt;
  final Function callback;
  final Map<String, dynamic> params;

  TimedSchedule(
    super.id,
    this.startAt,
    this.callback,
    this.params,
  );

  @override
  String toString() => "${super.toString()}: ${{
        "id": id,
        "startAt": startAt,
        "callback": callback,
        "params": params,
      }}";
}

class PeriodicSchedule extends TimedSchedule {
  final Duration duration;

  PeriodicSchedule(
    super.id,
    super.startAt,
    this.duration,
    super.callback,
    super.params,
  );

  @override
  String toString() => "${super.toString()}${{"duration": duration}}";
}
