import 'package:flutter/material.dart';
import 'package:mem/components/date_and_time/date_and_time_view.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/duration.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/values/colors.dart';

class ActListSubHeader extends StatelessWidget {
  final _subHeaderTextStyle = const TextStyle(color: secondaryGreyColor);

  final MapEntry<DateTime, List<Act>> _groupedAct;

  const ActListSubHeader(
    this._groupedAct, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DateAndTimeText(
              DateAndTime.from(_groupedAct.key),
              style: _subHeaderTextStyle,
            ),
            Text(
              _groupedAct.value.length.toString(),
              style: _subHeaderTextStyle,
            ),
            Text(
              _groupedAct.value
                  .fold<Duration>(
                      Duration.zero,
                      (previousValue, element) =>
                          previousValue + element.period.duration)
                  .format(),
              style: _subHeaderTextStyle,
            ),
          ],
        ),
      );
}
