import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/states.dart';

class MemItemsFormFields extends ConsumerWidget {
  final int? _memId;

  const MemItemsFormFields(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView(
        loadMemItems(_memId),
        (data) => _MemItemsFormFieldsComponent(
          ref.watch(memDetailProvider(_memId)).memItems,
          (value, memItem) => v(
            () {
              ref.watch(memItemsProvider(_memId).notifier).upsertAll(
                [memItem.copiedWith(value: () => value)],
                (tmp, item) => tmp.type == item.type &&
                        (tmp is SavedMemItemV2 && item is SavedMemItemV2)
                    ? tmp.id == item.id
                    : true,
              );
            },
            {value, memItem},
          ),
        ),
      );
}

class _MemItemsFormFieldsComponent extends StatelessWidget {
  final List<MemItemV2> _memItems;
  final Function(dynamic value, MemItemV2 memItem) _onChanged;

  const _MemItemsFormFieldsComponent(this._memItems, this._onChanged);

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return Column(
            children: [
              ..._memItems.map(
                (memItem) => TextFormField(
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
        _memItems,
      );
}
