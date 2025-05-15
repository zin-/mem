import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/values/dimens.dart';

const keyMemRepeatByNDayNotification = Key("mem-repeat-by-n-day-notification");

class MemRepeatByNDayNotificationView extends ConsumerWidget {
  final int? _memId;

  const MemRepeatByNDayNotificationView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final notification =
              ref.watch(memRepeatByNDayNotificationByMemIdProvider(_memId));

          return _MemRepeatByNDayNotificationView(
            notification.value.time,
            (value) {
              ref
                  .read(
                memNotificationsByMemIdProvider(_memId).notifier,
              )
                  .upsertAll(
                [
                  notification.updatedWith(
                    (v) => MemNotification.by(
                      v.memId,
                      v.type,
                      value == 0 ? null : value,
                      v.message,
                    ),
                  )
                ],
                (current, updating) =>
                    current.value.type == updating.value.type,
              );
            },
          );
        },
        {
          '_memId': _memId,
        },
      );
}

class _MemRepeatByNDayNotificationView extends StatelessWidget {
  final int? nDay;
  final void Function(int? value) _onNDayChanged;

  const _MemRepeatByNDayNotificationView(
    this.nDay,
    this._onNDayChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          final prefix = l10n.repeatByNDayPrefix;

          return ListTile(
            key: keyMemRepeatByNDayNotification,
            title: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (prefix.isNotEmpty) Text(prefix),
                TextFormField(
                  initialValue: (nDay ?? 0).toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _onNDayChanged(
                    value.isEmpty ? 1 : int.parse(value),
                  ),
                ),
                Text(l10n.repeatByNDaySuffix),
              ]
                  .map(
                    (e) => Flexible(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: defaultComponentPadding,
                        ),
                        child: e,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          );
        },
        {
          'nDay': nDay,
        },
      );
}
