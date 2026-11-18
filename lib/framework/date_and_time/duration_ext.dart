extension DurationExt on Duration {
  String formatElapsedTime() {
    // 桁。時・分・秒の欄。日は桁が伸びるので埋めない
    const fieldWidth = 2;
    String two(int n) => n.toString().padLeft(fieldWidth, '0');

    // 時間。1時間未満は秒まで出す。hoursPerDay 未満は分まで、それ以上は日と時間
    const showSecondsBelowHours = 1;
    if (inHours < showSecondsBelowHours) {
      return '${two(inMinutes)} m ${two(inSeconds.remainder(Duration.secondsPerMinute))} s';
    }
    if (inHours < Duration.hoursPerDay) {
      return '${two(inHours)} h ${two(inMinutes.remainder(Duration.minutesPerHour))} m';
    }
    return '$inDays d ${two(inHours.remainder(Duration.hoursPerDay))} h';
  }
}
