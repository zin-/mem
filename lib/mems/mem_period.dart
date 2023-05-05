import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/gui/date_and_time_text_form_field.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/mem_detail_states.dart';

class MemPeriodTextFormFields extends ConsumerWidget {
  final int? _memId;

  const MemPeriodTextFormFields(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.watch(editingMemProvider(_memId));

          return _MemPeriodTextFormFieldsComponent(
            // TODO Memにstartを持たせる
            mem.notifyAt,
            (pickedStart) => v(
              () => ref
                  .read(editingMemProvider(_memId).notifier)
                  // TODO startを更新する
                  .updatedBy(mem.copied()..notifyAt = pickedStart),
              pickedStart,
            ),
            // TODO Memにendを持たせる
            null,
            (pickedStart) => v(
              () => ref
                  .read(editingMemProvider(_memId).notifier)
                  // TODO endを更新する
                  .updatedBy(mem.copied()..notifyAt = pickedStart),
              pickedStart,
            ),
          );
        },
      );
}

class _MemPeriodTextFormFieldsComponent extends StatelessWidget {
  final DateAndTime? _start;
  final Function(DateAndTime? pickedStart) _onStartChanged;
  final DateAndTime? _end;
  final Function(DateAndTime? pickedStart) _onEndChanged;

  const _MemPeriodTextFormFieldsComponent(
    this._start,
    this._onStartChanged,
    this._end,
    this._onEndChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          return Column(
            children: [
              DateAndTimeTextFormFieldV2(
                _start,
                (pickedDateAndTime) => v(
                  () => _onStartChanged(pickedDateAndTime),
                  pickedDateAndTime,
                ),
                selectableRange:
                    _end == null ? null : DateAndTimePeriod(end: _end),
              ),
              DateAndTimeTextFormFieldV2(
                _end,
                (pickedDateAndTime) => v(
                  () => _onEndChanged(pickedDateAndTime),
                  pickedDateAndTime,
                ),
                selectableRange:
                    _start == null ? null : DateAndTimePeriod(start: _start),
              ),
            ],
          );
        },
      );
}
