String dateTimeText(DateTime dateTime) {
  final hour = dateTime.hour < 10 ? '0${dateTime.hour}' : '${dateTime.hour}';
  final minute =
      dateTime.minute < 10 ? '0${dateTime.minute}' : '${dateTime.minute}';
  return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute';
}
