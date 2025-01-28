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

          final enables =
              _memNotificationEntities.where((e) => e.value.isEnabled());

          final oneLine = MemNotification.toOneLine(
            enables.map((e) => e.value),
            l10n.repeatedNotificationText,
            l10n.repeatEveryNDayNotificationText,
            l10n.afterActStartedNotificationText,
          );
          final nDayMemNotification = enables
              .map((e) => e.value)
              .whereType<RepeatByNDayMemNotification>()
              .singleOrNull;
          final repeatMemNotifications = enables
              .map((e) => e.value)
              .whereType<RepeatMemNotification>()
              .map((e) => renderRepeatMemNotification(
                    context,
                    e,
                    nDayMemNotification,
                  ));

          return enables.isEmpty
              ? Text(
                  l10n.noNotifications,
                  style: TextStyle(
                    color: secondaryGreyColor,
                  ),
                )
              : Wrap(
                  children: [
                    ...repeatMemNotifications,
                    if (oneLine != null)
                      Text(
                        oneLine,
                        style: TextStyle(
                          color: null,
                        ),
                      )
                  ],
                );
        },
        {
          '_memNotificationEntities': _memNotificationEntities,
        },
      );
}

Widget renderRepeatMemNotification(
  BuildContext context,
  RepeatMemNotification repeat,
  RepeatByNDayMemNotification? repeatByNDay,
) =>
    v(
      () {
        final l10n = buildL10n(context);

        if (repeatByNDay != null && (repeatByNDay.time ?? 0) > 1) {
          return Text(
            l10n.repeatEveryNDayNotificationText(
              repeatByNDay.time.toString(),
              repeat.timeOfDay!.format(context),
            ),
          );
        } else {
          return Text(
            l10n.repeatedNotificationText(repeat.timeOfDay!.format(context)),
          );
        }
      },
      {
        'context': context,
        'repeatMemNotification': repeat,
        'nDayMemNotification': repeatByNDay,
      },
    );
