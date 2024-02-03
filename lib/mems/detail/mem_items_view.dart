import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_item.dart';

const keyMemMemo = Key("mem-memo");

class MemItemsFormFields extends ConsumerWidget {
  final int? _memId;

  const MemItemsFormFields(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _MemItemsFormFieldsComponent(
        ref.watch(memItemsProvider(_memId)),
        (entered, previous) => v(
          () {
            return ref.watch(memItemsProvider(_memId).notifier).upsertAll(
              [previous.copiedWith(value: () => entered)],
              (current, updating) {
                return current.type == updating.type &&
                        (current is SavedMemItem && updating is SavedMemItem)
                    ? current.id == updating.id
                    : true;
              },
            );
          },
          {"entered": entered, "previous": previous},
        ),
      );
}

class _MemItemsFormFieldsComponent extends StatelessWidget {
  final List<MemItem> _memItems;
  final Function(dynamic entered, MemItem previous) _onChanged;

  const _MemItemsFormFieldsComponent(this._memItems, this._onChanged);

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return Column(
            children: [
              ..._memItems.map(
                (memItem) => TextFormField(
                  key: keyMemMemo,
                  decoration: InputDecoration(
                    icon: const Icon(Icons.subject),
                    labelText: l10n.memMemoLabel,
                  ),
                  maxLines: null,
                  initialValue: memItem.value,
                  onChanged: (value) => _onChanged(value, memItem),
                ),
              ),
            ],
          );
        },
        {"_memItems": _memItems},
      );
}
