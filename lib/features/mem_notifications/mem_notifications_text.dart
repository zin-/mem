import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
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
          ref.watch(
            latestActsByMemV2Provider.select(
              (value) => value?[_memId],
            ),
          ),
        ),
        {
          '_memId': _memId,
        },
      );
}

class _MemNotificationText extends StatelessWidget {
  final Iterable<MemNotificationEntityV2> _memNotificationEntities;
  final TimeOfDay _startOfDay;
  final Act? _latestAct;

  const _MemNotificationText(
    this._memNotificationEntities,
    this._startOfDay,
    this._latestAct,
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
          final nextNotifyAt = MemNotification.nextNotifyAt(
            enables.map((e) => e.value),
            DateTimeExt.startOfToday(_startOfDay),
            _latestAct,
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
                    if (repeatMemNotification != null && nextNotifyAt != null)
                      renderRepeatMemNotification(
                        context,
                        repeatMemNotification,
                        nextNotifyAt,
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
  DateTime startOfToday,
) =>
    v(
      () => Text(
        repeat.timeOfDay!.format(context),
        style: TextStyle(
          color: DateTime.now().isAfter(startOfToday) ? warningColor : null,
        ),
      ),
      {
        'context': context,
        'repeatMemNotification': repeat,
        'startOfToday': startOfToday,
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
