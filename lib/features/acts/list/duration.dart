extension DurationExt on Duration {
  String format() => toString().split(".")[0];

  String formatHHmm() {
    final formatted = format();
    return formatted.substring(0, formatted.lastIndexOf(":"));
  }
}
