import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

const elapsePeriod = Duration(seconds: 1);

class ElapsedTimeView extends StatefulWidget {
  final DateTime _start;

  const ElapsedTimeView(this._start, {super.key});

  @override
  State<StatefulWidget> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<ElapsedTimeView> {
  Timer? _timer;
  Duration? elapsedTime;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      elapsePeriod,
      (timer) {
        setState(() {
          elapsedTime = DateTime.now().difference(widget._start);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) => v(
        () => Text(
          (elapsedTime ?? DateTime.now().difference(widget._start)).format(),
        ),
        elapsedTime,
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

extension on Duration {
  String format() => '$this'.split('.')[0].padLeft(8, '0');
}
