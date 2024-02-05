import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/values/colors.dart';

class MemNotificationsView extends ConsumerWidget {
  final int? _memId;

  const MemNotificationsView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemNotificationsView(
          ref.read(memNotificationsByMemIdProvider(_memId)),
        ),
        {"_memId": _memId},
      );
}

class _MemNotificationsView extends StatelessWidget {
  final List<MemNotification> _memNotifications;

  const _MemNotificationsView(this._memNotifications);

  @override
  Widget build(BuildContext context) => d(
        () {
          // TODO: implement build
          final hasEnabledNotifications = _memNotifications
              .where(
                (element) => element.isEnabled(),
              )
              .isNotEmpty;

          final l10n = buildL10n(context);
          final df = DateFormat(DateFormat.HOUR24_MINUTE);
          final a = _memNotifications
              .where((element) => element.isEnabled())
              .map((e) {
            switch (e.type) {
              case MemNotificationType.repeat:
                return l10n.repeat_notification(TimeOfDay.fromDateTime(
                  DateAndTime(0, 0, 0, 0, 0, e.time),
                ).format(context));
              case MemNotificationType.afterActStarted:
                return l10n.after_act_started_notification_t(
                    df.format(DateAndTime(0, 0, 0, 0, 0, e.time)));
            }
          });

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications,
              color: hasEnabledNotifications ? null : secondaryGreyColor,
            ),
            title: Text(
              hasEnabledNotifications ? a.join(", ") : "通知しない",
              style: TextStyle(
                color: hasEnabledNotifications ? null : secondaryGreyColor,
              ),
            ),
            trailing: IconButton(
              onPressed: () => d(() {
                // TODO transit notification page
              }),
              icon: Icon(
                hasEnabledNotifications ? Icons.edit : Icons.notification_add,
              ),
              tooltip: hasEnabledNotifications ? "通知を変更する" : "通知を追加する",
            ),
          );
        },
        {"_memNotifications": _memNotifications},
      );
}
