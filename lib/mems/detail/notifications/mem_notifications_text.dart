import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/values/colors.dart';

class MemNotificationText extends ConsumerWidget {
  final int? _memId;

  const MemNotificationText(
    this._memId, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemNotificationText(ref.watch(
          memNotificationsByMemIdProvider(_memId),
        )),
        {
          '_memId': _memId,
        },
      );
}

class _MemNotificationText extends StatelessWidget {
  final Iterable<MemNotificationEntityV2> _memNotificationEntities;

  const _MemNotificationText(
    this._memNotificationEntities,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          final oneLine = MemNotification.toOneLine(
            _memNotificationEntities.map((e) => e.value),
            l10n.repeatedNotificationText,
            l10n.repeatEveryNDayNotificationText,
            l10n.afterActStartedNotificationText,
            (dataAndTime) =>
                TimeOfDay.fromDateTime(dataAndTime).format(context),
          );

          return Text(
            oneLine ?? l10n.noNotifications,
            style: TextStyle(
              color: oneLine == null ? secondaryGreyColor : null,
            ),
          );
        },
        {
          '_memNotificationEntities': _memNotificationEntities,
        },
      );
}
