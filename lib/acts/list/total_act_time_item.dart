import 'package:flutter/material.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/duration.dart';
import 'package:mem/core/mem.dart';

class TotalActTimeListItem extends ListTile {
  TotalActTimeListItem(List<Act> acts, SavedMem? mem,  {super.key})
      : super(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(acts
                  .fold<Duration>(
                    Duration.zero,
                    (previousValue, element) =>
                        previousValue + element.period.duration,
                  )
                  .format()),
              Text(acts.length.toString()),
            ],
          ),
          subtitle: mem == null ? null : Text(mem.name),
        );
}
