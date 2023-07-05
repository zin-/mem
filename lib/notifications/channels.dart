import 'package:mem/components/l10n.dart';
import 'package:mem/notifications/notification_channel.dart';

final reminderChannel = NotificationChannel(
  'reminder',
  buildL10n().reminder_name,
  buildL10n().reminder_description,
);

final repeatedReminderChannel = NotificationChannel(
  'repeated-reminder',
  buildL10n().repeated_reminder_name,
  buildL10n().repeated_reminder_description,
);
