import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/components/mem/mem_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';

import 'states.dart';

class SingleSelectableMemListItem extends ConsumerWidget {
  final int _memId;

  const SingleSelectableMemListItem(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _SingleSelectableMemListItemComponent(
          ref.watch(memListProvider).firstWhere((_) => _.id == _memId),
          ref.watch(selectedMemIdsProvider)?.contains(_memId) ?? false,
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
    Mem memV1,
    bool isSelected,
    void Function(int? memId) onSelected,
  ) : super(
          title: MemNameText(SavedMemV2.fromV1(memV1)),
          subtitle: memV1.period == null ? null : MemPeriodTexts(memV1.id),
          trailing: Radio<int>(
            value: memV1.id,
            groupValue: isSelected ? memV1.id : null,
            onChanged: onSelected,
          ),
          onTap: () => onSelected(memV1.id),
        ) {
    verbose({
      'mem': memV1,
      'isSelected': isSelected,
    });
  }
}
