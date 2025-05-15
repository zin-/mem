import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';

const keyMemMemo = Key("mem-memo");

class MemItemsFormFields extends ConsumerWidget {
  final int? _memId;

  const MemItemsFormFields(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemItemsFormFields(
          ref.watch(memItemsByMemIdProvider(_memId)),
          (entered, previous) => v(
            () => ref.read(memItemsByMemIdProvider(_memId).notifier).upsertAll(
              [previous.copiedWith(value: () => entered)],
              (current, updating) =>
                  current.value.type == updating.value.type &&
                          (current is SavedMemItemEntityV2 &&
                              updating is SavedMemItemEntityV2)
                      ? current.id == updating.id
                      : true,
            ),
            {"entered": entered, "previous": previous},
          ),
        ),
        {
          "_memId": _memId,
        },
      );
}

class _MemItemsFormFields extends StatelessWidget {
  final List<MemItemEntityV2> _memItems;
  final void Function(dynamic entered, MemItemEntityV2 previous) _onChanged;

  const _MemItemsFormFields(this._memItems, this._onChanged);

  @override
  Widget build(BuildContext context) => v(
        () => Column(
          children: [
            ..._memItems.map(
              (memItem) => TextFormField(
                key: keyMemMemo,
                decoration: InputDecoration(
                  icon: const Icon(Icons.subject),
                  labelText: buildL10n(context).memMemoLabel,
                ),
                maxLines: null,
                initialValue: memItem.value.value,
                onChanged: (value) => _onChanged(value, memItem),
              ),
            ),
          ],
        ),
        {
          "_memItems": _memItems,
        },
      );
}
