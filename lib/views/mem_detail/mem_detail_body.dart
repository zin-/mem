import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_item_repository.dart'; // TODO repositoriesへの依存を排除する
import 'package:mem/views/atoms/async_value_view.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mem_name.dart';

class MemDetailBody extends StatelessWidget {
  final int? _memId;

  const MemDetailBody(this._memId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'_memId': _memId},
        () {
          return Consumer(
            builder: (context, ref, child) {
              final editingMem = ref.watch(editingMemProvider(_memId));

              return Column(
                children: [
                  MemNameTextFormField(
                    editingMem.name,
                    editingMem.id,
                    (value) => ref
                        .read(editingMemProvider(_memId).notifier)
                        .updatedBy(editingMem..name = value),
                  ),
                  AsyncValueView(
                    ref.watch(fetchMemById(_memId)),
                    (value) => _buildMemItemViews(_memId),
                  )
                ],
              );
            },
          );
        },
      );

  Widget _buildMemItemViews(int? memId) => v(
        {'memId': memId},
        () {
          return Consumer(
            builder: (context, ref, child) {
              final memItems = ref.watch(memItemsProvider(_memId));

              return SingleChildScrollView(
                child: Column(
                  children: [
                    ...(memItems == null || memItems.isEmpty
                            ? [
                                MemItemEntity(
                                  memId: _memId,
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
                            .read(memItemsProvider(_memId).notifier)
                            .updatedBy([memItem..value = value]),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
}
