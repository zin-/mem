import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

class ActListAppBar extends StatelessWidget {
  final String _title;
  final bool _isDateView;
  final void Function(bool changed) _changeDateViewMode;
  final bool _isTimeView;
  final void Function(bool changed) _changeTimeViewMode;

  const ActListAppBar(
    this._title,
    this._isDateView,
    this._changeDateViewMode,
    this._isTimeView,
    this._changeTimeViewMode, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: Text(_title),
          actions: [
            IconButton(
                onPressed: () => v(
                      () => _changeDateViewMode(!_isDateView),
                      {"_isDateView": _isDateView},
                    ),
                icon: Icon(
                  _isDateView
                      ? Icons.calendar_view_month
                      : Icons.calendar_view_day,
                )),
            IconButton(
              onPressed: () => v(
                () => _changeTimeViewMode(!_isTimeView),
                {"_isTimeView": _isTimeView},
              ),
              icon: Icon(
                _isTimeView ? Icons.numbers : Icons.access_time,
              ),
            )
          ],
        ),
        {
          "_title": _title,
          "_isDateView": _isDateView,
          "_isTimeView": _isTimeView,
        },
      );
}
