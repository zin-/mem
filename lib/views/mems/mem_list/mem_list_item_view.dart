import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mems/mem_done_checkbox.dart';
import 'package:mem/views/mems/mem_list/mem_list_page.dart';
import 'package:mem/views/mems/mem_name.dart';
import 'package:mem/views/mems/mem_notify_at.dart';

class MemListItemView extends StatelessWidget {
  final Mem _mem;

  const MemListItemView(this._mem, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {'_mem': _mem},
        () => Consumer(
          builder: (context, ref, child) {
            return ListTile(
              leading: MemDoneCheckbox(
                _mem.id,
                _mem.doneAt != null,
                (value) {
                  ref.read(editingMemProvider(_mem.id).notifier).updatedBy(
                      _mem..doneAt = value == true ? DateTime.now() : null);
                  ref.read(updateMem(_mem.id));
                },
              ),
              title: MemNameText(_mem.name, _mem.id),
              subtitle: buildMemNotifyAtText(_mem),
              onTap: () => showMemDetailPage(
                context,
                ref,
                _mem.id,
              ),
            );
          },
        ),
      );
}
