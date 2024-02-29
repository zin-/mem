import 'package:mem/framework/repository/entity.dart';

class Schedule extends Entity {
  final int id;
  final DateTime startAt;
  final Duration duration;
  final Function callback;
  final Map<String, dynamic> params;

  Schedule(
    this.id,
    this.startAt,
    this.duration,
    this.callback,
    this.params,
  );

  @override
  String toString() => "${super.toString()}: ${{
        "id": id,
        "startAt": startAt,
        "duration": duration,
        "callback": callback,
        "params": params,
      }}";
}
