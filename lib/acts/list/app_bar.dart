import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

class ActListAppBarIF {
  final String _title;
  final void Function(bool changed) _changeViewMode;

  ActListAppBarIF(this._title, this._changeViewMode);

  Map<String, dynamic> _toMap() => {
        "_title": _title,
      };

  @override
  String toString() => _toMap().toString();
}

class ActListAppBar extends StatelessWidget {
  final ActListAppBarIF _actListAppBarIF;
  final bool _isTimeView;

  const ActListAppBar(
    this._actListAppBarIF,
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
                () => _actListAppBarIF._changeViewMode(!_isTimeView),
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
          "_isTimeView": _isTimeView,
        },
      );
}
