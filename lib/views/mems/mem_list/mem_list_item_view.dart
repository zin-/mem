import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/domain/mem.dart';
import 'package:mem/views/colors.dart';
import 'package:mem/views/mems/mem_done_checkbox.dart';
import 'package:mem/views/mems/mem_list/mem_list_item_actions.dart';
import 'package:mem/views/mems/mem_name.dart';
import 'package:mem/views/mems/mem_notify_at.dart';

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
          subtitle: buildMemNotifyAtText(mem),
          onTap: onTap,
          tileColor: mem.isArchived() ? archivedColor : null,
        );
}
