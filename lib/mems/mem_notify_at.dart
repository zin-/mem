import 'package:flutter/material.dart';
import 'package:mem/domain/date_and_time.dart';
import 'package:mem/domain/mem.dart';
import 'package:mem/gui/colors.dart';
import 'package:mem/gui/date_and_time_text_form_field.dart';
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

class MemNotifyAtTextFormField extends StatelessWidget {
  final Mem _mem;
  final void Function(
    DateTime? pickedDate,
    TimeOfDay? pickedTimeOfDay,
  ) _onChanged;

  const MemNotifyAtTextFormField(this._mem, this._onChanged, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_mem': _mem, '_onChanged': _onChanged},
        () => HeroView(
          memNotifyAtTag(_mem.id),
          DateAndTimeTextFormField(
            date: _mem.notifyOn,
            timeOfDay: _mem.notifyAt,
            onChanged: _onChanged,
          ),
        ),
      );
}
