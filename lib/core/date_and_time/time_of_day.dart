class TimeOfDay {
  final int hour;
  final int minute;
  final int second;

  TimeOfDay(this.hour, this.minute, [this.second = 0]) {
    assert(hour < 24);
    assert(minute < 60);
    assert(second < 60);
  }

  factory TimeOfDay.fromSeconds(int second) {
    final hours = (second / 60 / 60).floor();
    final minutes = ((second - hours * 60 * 60) / 60).floor();
    final seconds = ((second - ((hours * 60) + minutes) * 60) / 60).floor();
    return TimeOfDay(hours, minutes, seconds);
  }

  int toSeconds() => ((hour * 60) + minute) * 60 + second;

  @override
  String toString() => '$hour:$minute${second == 0 ? '' : ':$second'}';
}
