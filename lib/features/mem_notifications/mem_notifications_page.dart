import 'package:flutter/material.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_name.dart';

import 'after_act_started_notification_view.dart';
import 'mem_repeat_by_day_of_week_notification_view.dart';
import 'mem_repeat_by_n_day_notification_view.dart';
import 'mem_repeated_notification_view.dart';

class MemNotificationsPage extends StatelessWidget {
  final int? _memId;

  const MemNotificationsPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () => Scaffold(
          appBar: AppBar(
            title: MemNameText(_memId),
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
        },
      );
}
