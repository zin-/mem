import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/line_chart/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/framework/date_and_time/time_text_form_field.dart';
import 'package:mem/framework/view/integer_text_form_field.dart';
import 'package:mem/values/dimens.dart';
import 'package:mem/generated/l10n/app_localizations.dart';

Key keyTargetValue = const Key('target-value');

const _maxCountValue = 999999;
const _maxTimeValue = 356400; // 99時間

class TargetText extends ConsumerWidget {
  final int? _memId;

  const TargetText(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetEntity = ref.watch(targetStateProvider(_memId));

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.check_circle),
      title: switch (targetEntity) {
        AsyncData(:final value) => _build(
            value, ref.read(targetStateProvider(_memId).notifier).updatedWith),
        AsyncError() => const Text('Oops, something unexpected happened'),
        _ => const CircularProgressIndicator(),
      },
    );
  }

  Widget _build(
    TargetEntity targetEntity,
    void Function({
      TargetType? Function()? targetType,
      TargetUnit? Function()? targetUnit,
      int? Function()? value,
      Period? Function()? period,
    }) onTargetChanged,
  ) =>
      Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Column(
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
                      onChanged: (v) => onTargetChanged(
                        targetType: () => TargetType.values[v!],
                      ),
                    ),
                  ),
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
                      onChanged: (v) => onTargetChanged(
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
                    child: switch (targetEntity.value.targetUnit) {
                      TargetUnit.count => IntegerTextFormField(
                          targetEntity.value.value,
                          key: keyTargetValue,
                          onChanged: (v) => onTargetChanged(
                            value: () => v,
                          ),
                        ),
                      TargetUnit.time => TimeTextFormField(
                          targetEntity.value.value,
                          (v) => onTargetChanged(
                            value: () =>
                                v == null || v > _maxTimeValue ? null : v,
                          ),
                        ),
                    },
                  ),
                  Text('/'),
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
                      onChanged: (v) => onTargetChanged(
                        period: () => Period.values[v!],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
}
