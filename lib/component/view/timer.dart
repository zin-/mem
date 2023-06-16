import 'dart:async';

import 'package:flutter/material.dart';

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
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          elapsedTime = DateTime.now().difference(widget._start);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) => Text(
        (elapsedTime ?? DateTime.now().difference(widget._start)).format(),
      );

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }
}

extension on Duration {
  String format() => '$this'.split('.')[0].padLeft(8, '0');
}
