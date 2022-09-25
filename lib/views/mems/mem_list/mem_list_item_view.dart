import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mems/mem_done_checkbox.dart';
import 'package:mem/views/mems/mem_list/mem_list_page.dart';
import 'package:mem/views/mems/mem_name.dart';

class MemListItemView extends StatelessWidget {
  final MemEntity _memEntity;

  const MemListItemView(this._memEntity, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'_memEntity': _memEntity},
        () => Consumer(
          builder: (context, ref, child) {
            return ListTile(
              leading: MemDoneCheckbox(
                _memEntity.id,
                _memEntity.doneAt != null,
                (value) {
                  ref.read(memProvider(_memEntity.id).notifier).updatedBy(
                      MemEntity.fromMap(_memEntity.toMap())
                        ..doneAt = value == true ? DateTime.now() : null);
                  ref.read(updateMem(_memEntity.id));
                },
              ),
              title: MemNameText(_memEntity.name, _memEntity.id),
              onTap: () => showMemDetailPage(
                context,
                ref,
                _memEntity.id,
              ),
            );
          },
        ),
      );
}
