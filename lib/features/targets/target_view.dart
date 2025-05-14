import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/line_chart/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/values/dimens.dart';

Key keyTargetValue = const Key('target-value');

class TargetText extends ConsumerWidget {
  final int? _memId;

  const TargetText(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    final targetEntity = ref.watch(targetStateProvider(_memId));
    final onTargetTypeChanged =
        ref.read(targetStateProvider(_memId).notifier).updatedWith;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.check_circle),
      // 1日20回以下、週40時間以上、1ヶ月に5時間以下みたいな感じ
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton(
                  isExpanded: true,
                  value: targetEntity.value.targetType.index,
                  items: TargetType.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.index,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => onTargetTypeChanged(
                    targetType: () => TargetType.values[v!],
                  ),
                ),
              ),
              SizedBox(width: defaultComponentPadding),
              Expanded(
                child: DropdownButton(
                  isExpanded: true,
                  value: targetEntity.value.targetUnit.index,
                  items: TargetUnit.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.index,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => onTargetTypeChanged(
                    targetUnit: () => TargetUnit.values[v!],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: defaultComponentPadding),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: keyTargetValue,
                  initialValue: targetEntity.value.value.toString(),
                  onChanged: (v) => onTargetTypeChanged(
                    value: () => int.parse(v),
                  ),
                ),
              ),
              SizedBox(width: defaultComponentPadding),
              Text('/'),
              SizedBox(width: defaultComponentPadding),
              Expanded(
                child: DropdownButton(
                  isExpanded: true,
                  value: targetEntity.value.period.index,
                  items: Period.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.index,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => onTargetTypeChanged(
                    period: () => Period.values[v!],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
