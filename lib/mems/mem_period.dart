import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/component/view/mem_list/states.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/component/view/date_and_time/date_and_time_period_view.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/mem_detail_states.dart';

class MemPeriodTexts extends ConsumerWidget {
  final int _memId;

  const MemPeriodTexts(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem =
              ref.watch(memListProviderV2).firstWhere((_) => _.id == _memId);

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
          final mem = ref.watch(editingMemProvider(_memId));

          return _MemPeriodTextFormFieldsComponent(
            mem.period,
            (pickedStart) => v(
              () => ref
                  .read(editingMemProvider(_memId).notifier)
                  .updatedBy(mem.copied()
                    ..period = pickedStart == null && mem.period?.end == null
                        ? null
                        : DateAndTimePeriod(
                            start: pickedStart,
                            end: mem.period?.end,
                          )),
              pickedStart,
            ),
            (pickedEnd) => v(
              () => ref
                  .read(editingMemProvider(_memId).notifier)
                  .updatedBy(mem.copied()
                    ..period = pickedEnd == null && mem.period?.start == null
                        ? null
                        : DateAndTimePeriod(
                            start: mem.period?.start,
                            end: pickedEnd,
                          )),
              pickedEnd,
            ),
          );
        },
      );
}

class _MemPeriodTextFormFieldsComponent extends StatelessWidget {
  final DateAndTimePeriod? _dateAndTimePeriod;
  final Function(DateAndTime? pickedStart) _onStartChanged;
  final Function(DateAndTime? pickedStart) _onEndChanged;

  const _MemPeriodTextFormFieldsComponent(
    this._dateAndTimePeriod,
    this._onStartChanged,
    this._onEndChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () => DateAndTimePeriodTextFormFields(
          _dateAndTimePeriod,
          _onStartChanged,
          _onEndChanged,
        ),
      );
}
