import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/components/mem/mem_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem_entity.dart';

import 'states.dart';

class SingleSelectableMemListItem extends ConsumerWidget {
  final int _memId;

  const SingleSelectableMemListItem(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _SingleSelectableMemListItemComponent(
          ref.watch(memListProvider).firstWhere((mem) => mem.id == _memId),
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
    SavedMemEntity mem,
    bool isSelected,
    void Function(int? memId) onSelected,
  ) : super(
          title: MemNameText(mem),
          subtitle: mem.period == null ? null : MemPeriodTexts(mem.id),
          trailing: Radio<int>(
            value: mem.id,
            groupValue: isSelected ? mem.id : null,
            onChanged: onSelected,
          ),
          onTap: () => onSelected(mem.id),
        ) {
    verbose({
      'mem': mem,
      'isSelected': isSelected,
    });
  }
}
