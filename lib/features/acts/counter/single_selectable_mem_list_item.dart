import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';

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
    SavedMemEntityV2 memEntity,
    bool isSelected,
    void Function(int? memId) onSelected,
  ) : super(
          title: MemNameText(memEntity),
          trailing: RadioGroup<int>(
            groupValue: isSelected ? memEntity.id : null,
            onChanged: (value) => onSelected(value),
            child: Radio<int>(
              value: memEntity.id,
            ),
          ),
          onTap: () => onSelected(memEntity.id),
        ) {
    verbose({
      'mem': memEntity,
      'isSelected': isSelected,
    });
  }
}

class _SingleSelectIndicator extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _SingleSelectIndicator({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // FIXME　RadioGroupとRadioListTileを使うべき
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: 2,
          ),
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
