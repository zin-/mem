import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/states.dart';

class MemItemsFormFields extends ConsumerWidget {
  final int? _memId;

  const MemItemsFormFields(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memItems = ref.watch(memItemsProvider(_memId));

    if (memItems == null) {
      ref.read(loadMemItems(_memId)).then((value) {
        ref.read(memItemsProvider(_memId).notifier).updatedBy(value);
      });
      return const CircularProgressIndicator();
    } else {
      return _MemItemsFormFieldsComponent(
        memItems,
        (value, memItem) => v(
          () {
            ref.read(memItemsProvider(_memId).notifier).upsertAll(
              [memItem..value = value],
              (tmp, item) => tmp.id == item.id,
            );
          },
          {value, memItem},
        ),
      );
    }
  }
}

class _MemItemsFormFieldsComponent extends StatelessWidget {
  final List<MemItem> _memItems;
  final Function(String value, MemItem memItem) _onChanged;

  const _MemItemsFormFieldsComponent(this._memItems, this._onChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._memItems.map(
          (memItem) => TextFormField(
            decoration: InputDecoration(
              icon: const Icon(Icons.subject),
              labelText: L10n().memMemoTitle(),
            ),
            maxLines: null,
            initialValue: memItem.value,
            onChanged: (value) => _onChanged(value, memItem),
          ),
        ),
      ],
    );
  }
}
