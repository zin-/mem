import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/date_and_time/date_and_time_period_view.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';

class MemPeriodTexts extends ConsumerWidget {
  final int _memId;

  const MemPeriodTexts(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem =
              ref.watch(memListProvider).firstWhere((_) => _.id == _memId);

          return _MemPeriodTexts(mem.period!);
        },
      );
}

class _MemPeriodTexts extends StatelessWidget {
  final DateAndTimePeriod _period;

  const _MemPeriodTexts(
    this._period,
  );

  @override
  Widget build(BuildContext context) =>
      v(() => DateAndTimePeriodTexts(_period));
}

class MemPeriodTextFormFields extends ConsumerWidget {
  final int? _memId;

  const MemPeriodTextFormFields(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.watch(memDetailProvider(_memId)).mem;

          return _MemPeriodTextFormFieldsComponent(
            mem.period,
            (pickedPeriod) => v(
              () => ref.read(editingMemProvider(_memId).notifier).updatedBy(
                    mem.copiedWith(period: () => pickedPeriod).toV1(),
                  ),
              pickedPeriod,
            ),
          );
        },
      );
}

class _MemPeriodTextFormFieldsComponent extends StatelessWidget {
  final DateAndTimePeriod? _dateAndTimePeriod;
  final Function(DateAndTimePeriod? pickedPeriod) _onPeriodChanged;

  const _MemPeriodTextFormFieldsComponent(
    this._dateAndTimePeriod,
    this._onPeriodChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () => DateAndTimePeriodTextFormFields(
          _dateAndTimePeriod,
          _onPeriodChanged,
        ),
      );
}
