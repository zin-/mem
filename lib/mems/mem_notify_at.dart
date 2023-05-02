import 'package:flutter/material.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/gui/colors.dart';
import 'package:mem/gui/date_and_time_view.dart';
import 'package:mem/gui/hero_view.dart';
import 'package:mem/logger/i/api.dart';

String memNotifyAtTag(int? memId) => heroTag('mem-notifyAt', memId);

class MemNotifyAtText extends DateAndTimeText {
  final int _memId;

  MemNotifyAtText(
    this._memId,
    DateAndTime memNotifyAt, {
    super.key,
  }) : super(
          memNotifyAt,
          style: TextStyle(
            color:
                memNotifyAt.isBefore(DateTime.now()) ? aposematicColor : null,
          ),
        );

  @override
  Widget build(BuildContext context) => v(
        {'_memId': _memId},
        () => HeroView(
          memNotifyAtTag(_memId),
          super.build(context),
        ),
      );
}
