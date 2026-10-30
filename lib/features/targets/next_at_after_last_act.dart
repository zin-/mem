import 'package:mem/features/acts/act.dart';
import 'package:mem/features/targets/target.dart';

class NextAtAfterLastAct {
  final DateTime at;

  NextAtAfterLastAct._(this.at);

  static NextAtAfterLastAct? of({
    required Target target,
    Act? latestAct,
    Act? scheduleAnchorAct,
  }) {
    final seconds = target.secondsAfterLastAct;
    if (seconds == null || latestAct == null) return null;
    if (latestAct.isActive || latestAct.state == ActState.paused) return null;

    final source = latestAct.isSkipped
        ? scheduleAnchorForNotifications(
            latestAct: latestAct,
            scheduleAnchorAct: scheduleAnchorAct,
          )
        : latestAct;
    final end = source != null && source.isFinished && !source.isSkipped
        ? source.period?.end
        : null;
    if (end == null) return null;
    return NextAtAfterLastAct._(end.add(Duration(seconds: seconds)));
  }
}
