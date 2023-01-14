import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/colors.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_list_page_states.dart';

import '../mems/mem_done_checkbox.dart';
import '../mems/mem_list_item_actions.dart';
import 'mem_name.dart';
import 'mem_notify_at.dart';

class MemListItemView extends ConsumerWidget {
  final MemId _memId;
  final void Function(MemId memId)? _onTapped;

  const MemListItemView(this._memId, this._onTapped, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        {'_memId': _memId},
        () {
          final memList = ref.watch(reactiveMemListProvider);
          final mem = memList.firstWhere((_) => _.id == _memId);
          return MemListItemViewComponent(
            mem,
            _onTapped,
            (bool? value, MemId memId) {
              value == true
                  ? ref.read(doneMem(memId))
                  : ref.read(undoneMem(memId));
            },
            key: key,
          );
        },
      );
}

class MemListItemViewComponent extends ListTile {
  MemListItemViewComponent(
    Mem mem,
    void Function(MemId memId)? onTap,
    void Function(bool? value, MemId memId) onMemDoneCheckboxTapped, {
    super.key,
  }) : super(
          leading: MemDoneCheckbox(
            mem,
            (value) => onMemDoneCheckboxTapped(value, mem.id),
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
