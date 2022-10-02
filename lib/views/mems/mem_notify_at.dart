import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';

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
