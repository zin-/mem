import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/after_act_started_notification_view.dart';
import 'package:mem/mems/detail/mem_repeated_notification_view.dart';
import 'package:mem/mems/detail/states.dart';

class MemNotificationsPage extends ConsumerWidget {
  final int? _memId;

  const MemNotificationsPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => d(
        () {
          // TODO: implement build
          final memName = ref.watch(
              editingMemByMemIdProvider(_memId).select((value) => value.name));

          return _MemNotificationsPage(
            memName,
          );
        },
        {"_memId": _memId},
      );
}

class _MemNotificationsPage extends StatelessWidget {
  final String _memName;

  const _MemNotificationsPage(this._memName);

  @override
  Widget build(BuildContext context) => d(
        () {
          // TODO: implement build
          return Scaffold(
            appBar: AppBar(
              title: Text(_memName),
            ),
            body: Flex(
              direction: Axis.vertical,
              children: [
                MemRepeatedNotificationView(null, (updating) => null),
                AfterActStartedNotificationView(
                  null,
                  "_message",
                  (time, message) => null,
                ),
              ],
            ),
          );
        },
        {"_memName": _memName},
      );
}
