import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/date_and_time/duration_ext.dart';

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
          (elapsedTime ?? DateTime.now().difference(widget._start))
              .format(),
        ),
        elapsedTime,
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
