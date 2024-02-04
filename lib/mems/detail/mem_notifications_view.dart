import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/values/colors.dart';

class MemNotificationsView extends ConsumerWidget {
  final int? _memId;

  const MemNotificationsView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => d(
        () {
          // TODO: implement build
          final memNotifications =
              ref.read(memNotificationsByMemIdProvider(_memId));

          return _MemNotificationsView(memNotifications);
        },
        {
          "_memId": _memId,
        },
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

          final notifyTimes =
              _memNotifications.where((element) => element.isRepeated()).map(
                    (e) => TimeOfDay.fromDateTime(
                      DateAndTime(0, 0, 0, 0, 0, e.time),
                    ).format(context),
                  );
          // TODO
          const span = "毎日";

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications,
              color: hasEnabledNotifications ? null : secondaryGreyColor,
            ),
            title: Text(
              hasEnabledNotifications ? span + notifyTimes.join(", ") : "通知しない",
              style: TextStyle(
                color: hasEnabledNotifications ? null : secondaryGreyColor,
              ),
            ),
            trailing: hasEnabledNotifications
                ? // TODO edit
                null
                : IconButton(
                    onPressed: () => d(() {}),
                    icon: const Icon(Icons.notification_add),
                    tooltip: "通知を追加する",
                  ),
          );
        },
        {"_memNotifications": _memNotifications},
      );
}
