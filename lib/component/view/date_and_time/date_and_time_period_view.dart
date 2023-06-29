import 'package:flutter/material.dart';

import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/component/view/date_and_time/date_and_time_text_form_field.dart';
import 'package:mem/component/view/date_and_time/date_and_time_view.dart';
import 'package:mem/logger/log_service.dart';

class DateAndTimePeriodTexts extends StatelessWidget {
  final DateAndTimePeriod _dateAndTimePeriod;

  const DateAndTimePeriodTexts(this._dateAndTimePeriod, {super.key});

  @override
  Widget build(BuildContext context) => v(() {
        return Wrap(
          children: [
            _dateAndTimePeriod.start == null
                ? const SizedBox.shrink()
                : DateAndTimeText(_dateAndTimePeriod.start!),
            const Text('~'),
            _dateAndTimePeriod.end == null
                ? const SizedBox.shrink()
                : DateAndTimeText(_dateAndTimePeriod.end!),
          ],
        );
      });
}

class DateAndTimePeriodTextFormFields extends StatelessWidget {
  final DateAndTimePeriod? _dateAndTimePeriod;
  final Function(DateAndTime? pickedStart) _onStartChanged;
  final Function(DateAndTime? pickedEnd) _onEndChanged;

  const DateAndTimePeriodTextFormFields(
    this._dateAndTimePeriod,
    this._onStartChanged,
    this._onEndChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          return Flex(
            direction: Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: [
              DateAndTimeTextFormFieldV2(
                _dateAndTimePeriod?.start,
                (pickedDateAndTime) => v(
                  () => _onStartChanged(pickedDateAndTime),
                  pickedDateAndTime,
                ),
                selectableRange: _dateAndTimePeriod?.end == null
                    ? null
                    : DateAndTimePeriod(
                        end: _dateAndTimePeriod?.end,
                      ),
              ),
              DateAndTimeTextFormFieldV2(
                _dateAndTimePeriod?.end,
                (pickedDateAndTime) => v(
                  () => _onEndChanged(pickedDateAndTime),
                  pickedDateAndTime,
                ),
                selectableRange: _dateAndTimePeriod?.start == null
                    ? null
                    : DateAndTimePeriod(
                        start: _dateAndTimePeriod?.start,
                      ),
              ),
            ],
          );
        },
      );
}
