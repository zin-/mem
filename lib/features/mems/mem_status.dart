sealed class MemStatus {
  const MemStatus._();

  static MemStatus of({
    required bool isDone,
    required bool hasEnabledNotifications,
    required bool hasUndoneChildren,
  }) {
    if (hasEnabledNotifications) {
      return NotifiedMemStatus._(isDone);
    }
    if (hasUndoneChildren && !isDone) {
      return const UndoneParentMemStatus._();
    }
    return DoneableMemStatus._(isDone);
  }
}

final class NotifiedMemStatus extends MemStatus {
  final bool isDone;

  const NotifiedMemStatus._(this.isDone) : super._();
}

final class DoneableMemStatus extends MemStatus {
  final bool isDone;

  const DoneableMemStatus._(this.isDone) : super._();
}

final class UndoneParentMemStatus extends MemStatus {
  const UndoneParentMemStatus._() : super._();
}
