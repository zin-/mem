import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/views/mems/mem_done_checkbox.dart';
import 'package:mem/views/mems/mem_list/mem_list_item_actions.dart';
import 'package:mem/views/mems/mem_name.dart';
import 'package:mem/views/mems/mem_notify_at.dart';

class MemListItemView extends StatelessWidget {
  final Mem _mem;
  final Function() _onTap;

  const MemListItemView(this._mem, this._onTap, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {'_mem': _mem},
        () => Consumer(
          builder: (context, ref, child) {
            return ListTile(
              leading: MemDoneCheckbox(
                _mem,
                (value) {
                  value == true
                      ? ref.read(doneMem(_mem.id))
                      : ref.read(undoneMem(_mem.id));
                },
                memArchivedAt: _mem.archivedAt,
              ),
              title: MemNameText(_mem.name, _mem.id),
              subtitle: buildMemNotifyAtText(_mem),
              onTap: _onTap,
            );
          },
        ),
      );
}
