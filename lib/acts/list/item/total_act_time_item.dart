import 'package:flutter/material.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/acts/list/duration.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/transitions.dart';
import 'package:mem/mems/mem_entity.dart';

class TotalActTimeListItem extends StatelessWidget {
  final List<Act> _actList;
  final SavedMemEntity? _mem;

  const TotalActTimeListItem(this._actList, this._mem, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          return ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_actList
                    .fold<Duration>(
                      Duration.zero,
                      (previousValue, element) =>
                          previousValue + element.period.duration,
                    )
                    .format()),
                Text(_actList.length.toString()),
              ],
            ),
            subtitle: _mem == null ? null : Text(_mem.name),
            trailing: _mem == null
                ? null
                : IconButton(
                    onPressed: () => showMemDetailPage(context, null, _mem.id),
                    icon: const Icon(Icons.arrow_forward),
                  ),
          );
        },
        {"_actList": _actList, "_mem": _mem},
      );
}
