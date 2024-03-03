import 'package:mem/framework/repository/entity.dart';

class Schedule extends Entity {
  final int id;
  final DateTime startAt;
  final Function callback;
  final Map<String, dynamic> params;

  Schedule(
    this.id,
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

class PeriodicSchedule extends Schedule {
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
