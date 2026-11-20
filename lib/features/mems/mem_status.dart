import 'package:mem/features/acts/act.dart';

enum ActProgress {
  active,
  paused,
  idle;

  static ActProgress of(Act? act) {
    if (act is ActiveAct) return ActProgress.active;
    if (act is PausedAct) return ActProgress.paused;
    return ActProgress.idle;
  }
}

sealed class MemStatus {
  const MemStatus._();

  static MemStatus of({
    required Act? latestAct,
    required bool isDone,
    required bool hasEnabledNotifications,
    required bool hasUndoneChildren,
  }) {
    final progress = ActProgress.of(latestAct);
    if (hasEnabledNotifications) {
      return NotifiedMemStatus._(progress, isDone);
    }
    if (hasUndoneChildren && !isDone) {
      return const UndoneParentMemStatus._();
    }
    return DoneableMemStatus._(progress, isDone);
  }
}

final class NotifiedMemStatus extends MemStatus {
  final ActProgress progress;
  final bool isDone;

  const NotifiedMemStatus._(this.progress, this.isDone) : super._();
}

final class DoneableMemStatus extends MemStatus {
  final ActProgress progress;
  final bool isDone;

  const DoneableMemStatus._(this.progress, this.isDone) : super._();
}

final class UndoneParentMemStatus extends MemStatus {
  const UndoneParentMemStatus._() : super._();
}
