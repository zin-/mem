import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/domain/mem.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/gui/async_value_view.dart';
import 'package:mem/view/mems/mem_detail/mem_detail_states.dart';

class MemItemsView extends ConsumerWidget {
  final int? _memId;

  const MemItemsView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        {'_memId': _memId},
        () => AsyncValueView<Iterable<MemItem>>(
          ref.watch(loadMemItems(_memId)),
          (memItems) => MemItemsViewComponent(
            memItems,
            (value, memItem) => ref
                .read(memItemsProvider(_memId).notifier)
                .updatedBy([memItem..value = value]),
          ),
        ),
      );
}

class MemItemsViewComponent extends StatelessWidget {
  final Iterable<MemItem> _memItems;
  final Function(String value, MemItem memItem) _onChanged;

  const MemItemsViewComponent(this._memItems, this._onChanged, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_memItems': _memItems, '_onChanged': _onChanged},
        () => Column(
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
        ),
      );
}
