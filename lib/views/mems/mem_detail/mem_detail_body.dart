import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/atoms/async_value_view.dart';
import 'package:mem/views/mems/mem_done_checkbox.dart';
import 'package:mem/views/mems/mem_name.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_states.dart';

class MemDetailBody extends StatelessWidget {
  final int? _memId;

  const MemDetailBody(this._memId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'_memId': _memId},
        () {
          return SingleChildScrollView(
            child: Consumer(
              builder: (context, ref, child) {
                final editingMem = ref.watch(editingMemProvider(_memId));

                return Column(
                  children: [
                    MemNameTextFormField(
                      editingMem.name,
                      editingMem.id,
                      (value) => ref
                          .read(editingMemProvider(_memId).notifier)
                          .updatedBy(
                            Mem.copyFrom(editingMem..name = value),
                          ),
                    ),
                    MemDoneCheckbox(
                      editingMem.id,
                      editingMem.doneAt != null,
                      (value) => ref
                          .read(editingMemProvider(_memId).notifier)
                          .updatedBy(
                            Mem.copyFrom(editingMem
                              ..doneAt = value == true ? DateTime.now() : null),
                          ),
                    ),
                    AsyncValueView(
                      ref.watch(fetchMemItemByMemIdV2(_memId)),
                      (value) => _buildMemItemViews(_memId),
                    )
                  ],
                );
              },
            ),
          );
        },
      );

  Widget _buildMemItemViews(int? memId) => v(
        {'memId': memId},
        () {
          return Consumer(
            builder: (context, ref, child) {
              final memItems = ref.watch(memItemsProvider(memId));

              return Column(
                children: [
                  ...(memItems == null || memItems.isEmpty
                          ? [
                              MemItem(
                                memId: memId,
                                type: MemItemType.memo,
                              ),
                            ]
                          : memItems)
                      .map(
                    (memItem) => TextFormField(
                      decoration: InputDecoration(
                        icon: const Icon(Icons.subject),
                        labelText: L10n().memMemoTitle(),
                      ),
                      maxLines: null,
                      initialValue: memItem.value,
                      onChanged: (value) => ref
                          .read(memItemsProvider(memId).notifier)
                          .updatedBy([memItem..value = value]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
}
