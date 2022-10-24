import 'package:flutter/material.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/views/_atoms/hero_view.dart';
import 'package:mem/views/_molecules/date_and_time_text_form_field.dart';
import 'package:mem/views/_atoms/date_and_time_view.dart';

String memNotifyAtTag(int? memId) => heroTag('mem-notifyAt', memId);

Widget? buildMemNotifyAtText(Mem mem) => v(
      {'mem': mem},
      () {
        final memNotifyOn = mem.notifyOn;
        return memNotifyOn == null
            ? null
            : MemNotifyAtText(mem.id, memNotifyOn, mem.notifyAt);
      },
    );

class MemNotifyAtText extends DateAndTimeText {
  final int _memId;

  MemNotifyAtText(
    this._memId,
    DateTime memNotifyOn,
    TimeOfDay? memNotifyAt, {
    super.key,
  }) : super(DateAndTime(
          memNotifyOn.year,
          memNotifyOn.month,
          memNotifyOn.day,
          memNotifyAt?.hour,
          memNotifyAt?.minute,
        ));

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
        () {
          final memNotifyOn = _mem.notifyOn;

          return HeroView(
            memNotifyAtTag(_mem.id),
            DateAndTimeTextFormField(
              memNotifyOn == null
                  ? null
                  : DateAndTime.from(
                      memNotifyOn,
                      timeOfDay: _mem.notifyAt,
                    ),
              (pickedDateAndTime) {
                _onChanged(
                  pickedDateAndTime?.dateTime,
                  pickedDateAndTime?.timeOfDay,
                );
              },
            ),
          );
        },
      );
}
