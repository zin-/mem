import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';

import 'after_act_started_notification_view.dart';
import 'mem_repeat_by_day_of_week_notification_view.dart';
import 'mem_repeat_by_n_day_notification_view.dart';
import 'mem_repeated_notification_view.dart';

class MemNotificationsPage extends ConsumerWidget {
  final int? _memId;

  const MemNotificationsPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemNotificationsPage(
          _memId,
          ref.watch(
            editingMemByMemIdProvider(_memId).select(
              (value) => value.name,
            ),
          ),
        ),
        {
          "_memId": _memId,
        },
      );
}

class _MemNotificationsPage extends StatelessWidget {
  final int? _memId;
  final String _memName;

  const _MemNotificationsPage(this._memId, this._memName);

  @override
  Widget build(BuildContext context) => v(
        () => Scaffold(
          appBar: AppBar(
            title: Text(_memName),
          ),
          body: SingleChildScrollView(
            child: Flex(
              direction: Axis.vertical,
              children: [
                MemRepeatedNotificationView(_memId),
                MemRepeatByNDayNotificationView(_memId),
                MemRepeatByDaysOfWeekNotificationView(_memId),
                AfterActStartedNotificationView(_memId),
              ],
            ),
          ),
        ),
        {
          "_memId": _memId,
          "_memName": _memName,
        },
      );
}
