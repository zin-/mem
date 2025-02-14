import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/time_of_day.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/settings/preference/keys.dart';
import 'package:mem/settings/states.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/constants.dart';

class MemNotificationText extends ConsumerWidget {
  final int? _memId;

  const MemNotificationText(
    this._memId, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemNotificationText(
          ref.watch(memNotificationsByMemIdProvider(_memId)),
          ref.read(preferencesProvider.select(
            (v) => (v.value?[startOfDayKey] ?? defaultStartOfDay) as TimeOfDay,
          )),
        ),
        {
          '_memId': _memId,
        },
      );
}

class _MemNotificationText extends StatelessWidget {
  final Iterable<MemNotificationEntityV2> _memNotificationEntities;
  final TimeOfDay _startOfDay;

  const _MemNotificationText(
    this._memNotificationEntities,
    this._startOfDay,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          final enables =
              _memNotificationEntities.where((e) => e.value.isEnabled());

          final oneLine = MemNotification.toOneLine(
            enables.map((e) => e.value),
            l10n.afterActStartedNotificationText,
          );
          final repeatMemNotification = enables
              .map((e) => e.value)
              .whereType<RepeatMemNotification>()
              .singleOrNull;
          final nDayMemNotification = enables
              .map((e) => e.value)
              .whereType<RepeatByNDayMemNotification>()
              .singleOrNull;

          return enables.isEmpty
              ? Text(
                  l10n.noNotifications,
                  style: TextStyle(
                    color: secondaryGreyColor,
                  ),
                )
              : Wrap(
                  spacing: 4.0,
                  children: [
                    if (repeatMemNotification != null)
                      renderRepeatMemNotification(
                        context,
                        repeatMemNotification,
                        _startOfDay,
                      ),
                    if (nDayMemNotification != null)
                      renderRepeatByNDayMemNotification(
                        context,
                        nDayMemNotification,
                      ),
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
          '_startOfDay': _startOfDay,
        },
      );
}

Widget renderRepeatMemNotification(
  BuildContext context,
  RepeatMemNotification repeat,
  TimeOfDay startOfDay,
) =>
    v(
      () {
        final now = TimeOfDay.now();

        final style = TextStyle(
          color: repeat.timeOfDay!.isAfterWithStartOfDay(now, startOfDay)
              ? null
              : warningColor,
        );

        return Text(
          repeat.timeOfDay!.format(context),
          style: style,
        );
      },
      {
        'context': context,
        'repeatMemNotification': repeat,
        'startOfDay': startOfDay,
      },
    );

Widget renderRepeatByNDayMemNotification(
  BuildContext context,
  RepeatByNDayMemNotification repeatByNDay,
) =>
    v(
      () {
        final l10n = buildL10n(context);

        if (repeatByNDay.time == 1) {
          return Text(l10n.repeatEverydayNotificationText);
        } else {
          return Text(
            l10n.repeatEveryNDayNotificationText(repeatByNDay.time.toString()),
          );
        }
      },
      {
        'context': context,
        'repeatMemNotification': repeatByNDay,
      },
    );
