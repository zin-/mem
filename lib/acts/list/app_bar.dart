import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

class ActListAppBarIF {
  final String _title;
  final void Function(bool changed) _changeDateViewMode;
  final void Function(bool changed) _changeTimeViewMode;

  ActListAppBarIF(
    this._title,
    this._changeDateViewMode,
    this._changeTimeViewMode,
  );

  Map<String, dynamic> _toMap() => {
        "_title": _title,
      };

  @override
  String toString() => _toMap().toString();
}

class ActListAppBar extends StatelessWidget {
  final ActListAppBarIF _actListAppBarIF;
  final bool _isDateView;
  final bool _isTimeView;

  const ActListAppBar(
    this._actListAppBarIF,
    this._isDateView,
    this._isTimeView, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: Text(_actListAppBarIF._title),
          actions: [
            IconButton(
                onPressed: () => v(
                      () => _actListAppBarIF._changeDateViewMode(!_isDateView),
                      {"_isDateView": _isDateView},
                    ),
                icon: Icon(
                  _isDateView
                      ? Icons.calendar_view_month
                      : Icons.calendar_view_day,
                )),
            IconButton(
              onPressed: () => v(
                () => _actListAppBarIF._changeTimeViewMode(!_isTimeView),
                {"_isTimeView": _isTimeView},
              ),
              icon: Icon(
                _isTimeView ? Icons.numbers : Icons.access_time,
              ),
            )
          ],
        ),
        {
          "_actListAppBarIF": _actListAppBarIF,
          "_isDateView": _isDateView,
          "_isTimeView": _isTimeView,
        },
      );
}
