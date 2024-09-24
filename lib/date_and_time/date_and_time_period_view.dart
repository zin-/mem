import 'package:flutter/material.dart';
import 'package:mem/date_and_time/date_and_time_text_form_field.dart';
import 'package:mem/date_and_time/date_and_time_view.dart';
import 'package:mem/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

class DateAndTimePeriodTexts extends StatelessWidget {
  final DateAndTimePeriod _dateAndTimePeriod;
  final bool _showDate;

  final TextStyle? _style;

  const DateAndTimePeriodTexts(
    this._dateAndTimePeriod, {
    super.key,
    showDate = true,
    TextStyle? style,
  })  : _showDate = showDate,
        _style = style;

  @override
  Widget build(BuildContext context) => v(() {
        return Wrap(
          children: [
            _dateAndTimePeriod.start == null
                ? const SizedBox.shrink()
                : DateAndTimeText(
                    _dateAndTimePeriod.start!,
                    showTime: _showDate,
                    style: _style,
                  ),
            const Text('~'),
            _dateAndTimePeriod.end == null
                ? const SizedBox.shrink()
                : DateAndTimeText(
                    _dateAndTimePeriod.end!,
                    showTime: _showDate,
                    style: _style,
                  ),
          ],
        );
      });
}

class DateAndTimePeriodTextFormFields extends StatelessWidget {
  final DateAndTimePeriod? _dateAndTimePeriod;
  final Function(DateAndTimePeriod? picked) _onChanged;

  const DateAndTimePeriodTextFormFields(
    this._dateAndTimePeriod,
    this._onChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => Flex(
          direction: Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          children: [
            DateAndTimeTextFormField(
              _dateAndTimePeriod?.start,
              (pickedDateAndTime) => v(
                () =>
                    _dateAndTimePeriod?.end == null && pickedDateAndTime == null
                        ? _onChanged(null)
                        : _onChanged(DateAndTimePeriod(
                            start: pickedDateAndTime,
                            end: _dateAndTimePeriod?.end,
                          )),
                pickedDateAndTime,
              ),
              selectableRange: _dateAndTimePeriod?.end == null
                  ? null
                  : DateAndTimePeriod(
                      end: _dateAndTimePeriod?.end,
                    ),
            ),
            DateAndTimeTextFormField(
              _dateAndTimePeriod?.end,
              (pickedDateAndTime) => v(
                () => _dateAndTimePeriod?.start == null &&
                        pickedDateAndTime == null
                    ? _onChanged(null)
                    : _onChanged(DateAndTimePeriod(
                        start: _dateAndTimePeriod?.start,
                        end: pickedDateAndTime,
                      )),
                pickedDateAndTime,
              ),
              selectableRange: _dateAndTimePeriod?.start == null
                  ? null
                  : DateAndTimePeriod(
                      start: _dateAndTimePeriod?.start,
                    ),
            ),
          ],
        ),
        _dateAndTimePeriod,
      );
}
