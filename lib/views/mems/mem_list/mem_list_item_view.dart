import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mems/mem_done_checkbox.dart';
import 'package:mem/views/mems/mem_list/mem_list_page.dart';
import 'package:mem/views/mems/mem_name.dart';

class MemListItemView extends StatelessWidget {
  final int _memId;

  const MemListItemView(this._memId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'_memId': _memId},
        () => Consumer(
          builder: (context, ref, child) {
            final mem = ref.watch(memProvider(_memId));

            if (mem == null) {
              ref.watch(fetchMemByIdV2(_memId));
              return const SizedBox.shrink();
            } else {
              return ListTile(
                leading: MemDoneCheckbox(
                  mem.id,
                  mem.doneAt != null,
                  (value) {
                    ref.read(memProvider(_memId).notifier).updatedBy(
                        MemEntity.fromMap(mem.toMap())
                          ..doneAt = value == true ? DateTime.now() : null);
                    ref.read(updateMem(_memId));
                  },
                ),
                title: MemNameText(mem.name, mem.id),
                onTap: () => showMemDetailPage(
                  context,
                  ref,
                  mem.id,
                ),
              );
            }
          },
        ),
      );
}
