import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/logger/log_service.dart';

import 'states.dart';

class SingleSelectableMemListItem extends ConsumerWidget {
  final int _memId;

  const SingleSelectableMemListItem(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _SingleSelectableMemListItemComponent(
          _memId,
          ref.watch(selectedMemIdsProvider).contains(_memId),
          (memId) => v(
            () => ref
                .read(selectedMemIdsProvider.notifier)
                .updatedBy(memId == null ? [] : [memId]),
            memId,
          ),
        ),
        _memId,
      );
}

class _SingleSelectableMemListItemComponent extends ListTile {
  _SingleSelectableMemListItemComponent(
    MemId memId,
    bool isSelected,
    void Function(int? memId) onSelected,
  ) : super(
          title: MemNameText(memId),
          trailing: RadioGroup<int>(
            groupValue: isSelected ? memId : null,
            onChanged: (value) => onSelected(value),
            child: Radio<int>(
              value: memId!,
            ),
          ),
          onTap: () => onSelected(memId),
        ) {
    verbose({
      'memId': memId,
      'isSelected': isSelected,
    });
  }
}
