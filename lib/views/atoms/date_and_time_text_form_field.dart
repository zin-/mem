import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';

class DateAndTimeTextFormField extends StatelessWidget {
  final DateTime? _date;
  final DateFormat? _dateFormat;
  final TimeOfDay? _timeOfDay;

  const DateAndTimeTextFormField({
    required DateTime? date,
    required TimeOfDay? timeOfDay,
    DateFormat? dateFormat,
    Key? key,
  })  : _date = date,
        _timeOfDay = timeOfDay,
        _dateFormat = dateFormat,
        super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'_date': _date, '_timeOfDay': _timeOfDay},
        () {
          final allDay = _timeOfDay == null;

          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.calendar_month),
                    hintText: L10n().yyyyMMdd(),
                  ),
                  initialValue: _date == null
                      ? ''
                      : (_dateFormat ?? DateFormat(L10n().yyyyMMdd()))
                          .format(_date!),
                ),
              ),
              allDay
                  ? const SizedBox.shrink()
                  : Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: L10n().yyyyMMdd(),
                        ),
                        initialValue: _timeOfDay!.format(context),
                      ),
                    ),
              Switch(
                value: allDay,
                onChanged: (value) {},
              ),
              _date == null && _timeOfDay == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.clear),
                    ),
            ],
          );
        },
      );
}
