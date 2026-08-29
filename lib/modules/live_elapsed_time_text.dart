import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mem/features/logger/log_service.dart';

const _tickInterval = Duration(seconds: 1);

class LiveElapsedTimeText extends StatefulWidget {
  final DateTime _start;

  const LiveElapsedTimeText(this._start, {super.key});

  @override
  State<StatefulWidget> createState() => _LiveElapsedTimeTextState();
}

class _LiveElapsedTimeTextState extends State<LiveElapsedTimeText> {
  Timer? _timer;
  Duration? elapsedTime;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      _tickInterval,
      (timer) {
        setState(() {
          elapsedTime = DateTime.now().difference(widget._start);
        });
      },
    );
  }

  @override
  void didUpdateWidget(covariant LiveElapsedTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._start != widget._start) {
      setState(() {
        elapsedTime = null;
      });
    }
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

String formatElapsedTime(Duration elapsed) {
  if (elapsed.inHours < 1) {
    return '${_two(elapsed.inMinutes)}:${_two(elapsed.inSeconds.remainder(60))}';
  }
  if (elapsed.inHours < 24) {
    return '${_two(elapsed.inHours)}:${_two(elapsed.inMinutes.remainder(60))}';
  }
  return '${elapsed.inDays}d ${_two(elapsed.inHours.remainder(24))}';
}

String _two(int n) => n.toString().padLeft(2, '0');

extension on Duration {
  String format() => formatElapsedTime(this);
}
