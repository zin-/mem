import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/transitions.dart';
import 'package:mem/mems/mem_entity.dart';

class TotalActTimeListItem extends StatelessWidget {
  final List<Act> _actList;
  final SavedMemEntityV2? _memEntity;

  const TotalActTimeListItem(this._actList, this._memEntity, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () => ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_actList
                  .fold<Duration>(
                    Duration.zero,
                    (previousValue, element) =>
                        previousValue +
                        (element.period?.duration ?? Duration.zero),
                  )
                  .format()),
              Text(_actList.length.toString()),
            ],
          ),
          subtitle: _memEntity == null ? null : Text(_memEntity.value.name),
          trailing: _memEntity == null
              ? null
              : IconButton(
                  onPressed: () =>
                      showMemDetailPage(context, null, _memEntity.id),
                  icon: const Icon(Icons.arrow_forward),
                ),
        ),
        {
          '_actList': _actList,
          '_mem': _memEntity,
        },
      );
}
