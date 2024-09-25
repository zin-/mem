import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/settings/states.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/constants.dart';

class MemPeriodTexts extends ConsumerWidget {
  final int _memId;

  const MemPeriodTexts(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemPeriodTexts(
          (ref.watch(memListProvider).firstWhere((mem) => mem.id == _memId))
              .period!,
          ref.watch(startOfDayProvider) ?? defaultStartOfDay,
        ),
      );
}

class _MemPeriodTexts extends StatelessWidget {
  final DateAndTimePeriod _period;
  final TimeOfDay _startOfDay;

  const _MemPeriodTexts(
    this._period,
    this._startOfDay,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final now = DateTime.now();

          return DateAndTimePeriodTexts(
            _period,
            style: _period.compareWithDateAndTime(DateAndTime(
                      now.year,
                      now.month,
                      now.day,
                      _startOfDay.hour,
                      _startOfDay.minute,
                    )) <
                    0
                ? const TextStyle(color: warningColor)
                : null,
          );
        },
        {"_period": _period, "_startOfDay": _startOfDay},
      );
}

class MemPeriodTextFormFields extends ConsumerWidget {
  final int? _memId;

  const MemPeriodTextFormFields(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.watch(editingMemByMemIdProvider(_memId));

          return _MemPeriodTextFormFieldsComponent(
            mem.period,
            (pickedPeriod) => v(
              () => ref
                  .read(editingMemByMemIdProvider(_memId).notifier)
                  .updatedBy(
                    mem.copiedWith(period: () => pickedPeriod),
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
