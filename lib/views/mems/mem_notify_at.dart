import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/views/molecules/date_and_time_text_form_field.dart';

Widget? buildMemNotifyAtText(Mem mem) {
  if (mem.notifyOn == null) {
    return null;
  } else {
    return MemNotifyAtText(mem);
  }
}

class MemNotifyAtText extends StatelessWidget {
  final Mem _mem;
  final DateFormat _dateFormat = DateFormat.yMd();

  MemNotifyAtText(this._mem, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_mem': _mem},
        () {
          final notifyOnText = _dateFormat.format(_mem.notifyOn!);
          final notifyAtText = _mem.notifyAt?.format(context);

          return Text(
            [notifyOnText, notifyAtText]
                .where((element) => element != null)
                .join(' '),
          );
        },
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
        () {
          return DateAndTimeTextFormField(
            date: _mem.notifyOn,
            timeOfDay: _mem.notifyAt,
            onChanged: _onChanged,
          );
        },
      );
}
