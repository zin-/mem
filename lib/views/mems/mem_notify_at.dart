import 'package:flutter/material.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/views/atoms/hero_view.dart';
import 'package:mem/views/molecules/date_and_time_text_form_field.dart';
import 'package:mem/views/molecules/date_and_time_view.dart';

String memNotifyAtTag(int? memId) => heroTag('mem-notifyAt', memId);

Widget? buildMemNotifyAtText(Mem mem) =>
    mem.notifyOn == null ? null : MemNotifyAtText(mem);

class MemNotifyAtText extends StatelessWidget {
  final Mem _mem;

  const MemNotifyAtText(this._mem, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_mem': _mem},
        () => HeroView(
          memNotifyAtTag(_mem.id),
          DateAndTimeText(_mem.notifyOn, _mem.notifyAt),
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
