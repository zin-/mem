import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/domain/date_and_time.dart';
import 'package:mem/domain/mem.dart';

import 'colors.dart';
import 'mem_done_checkbox.dart';
import 'mem_list_item_actions.dart';
import 'mem_name.dart';
import 'mem_notify_at.dart';

class MemListItemView extends ListTile {
  MemListItemView(Mem mem, void Function() onTap, {super.key})
      : super(
          leading: Consumer(
            builder: (context, ref, child) {
              return MemDoneCheckbox(
                mem,
                (value) => {
                  value == true
                      ? ref.read(doneMem(mem.id))
                      : ref.read(undoneMem(mem.id))
                },
              );
            },
          ),
          title: MemNameText(mem.name, mem.id),
          subtitle: mem.notifyOn == null
              ? null
              : MemNotifyAtText(mem.id,
                  DateAndTime.from(mem.notifyOn!, timeOfDay: mem.notifyAt)),
          onTap: onTap,
          tileColor: mem.isArchived() ? archivedColor : null,
        );
}
