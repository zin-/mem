import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/colors.dart';

import '../mems/mem_done_checkbox.dart';
import '../mems/mem_list_item_actions.dart';
import 'mem_name.dart';
import 'mem_notify_at.dart';

class MemListItemView extends ListTile {
  MemListItemView(Mem mem, void Function(MemId memId)? onTap, {super.key})
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
          subtitle: mem.notifyAtV2 == null
              ? null
              : MemNotifyAtText(
                  mem.id,
                  mem.notifyAtV2!,
                ),
          onTap: onTap == null ? null : () => onTap(mem.id),
          tileColor: mem.isArchived() ? archivedColor : null,
        );
}
