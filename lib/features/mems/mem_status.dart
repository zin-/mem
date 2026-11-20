enum MemStatus {
  notified,
  doneable,
  undoneParent;

  static MemStatus of({
    required bool isDone,
    required bool hasEnabledNotifications,
    required bool hasUndoneChildren,
  }) {
    if (hasEnabledNotifications) {
      return MemStatus.notified;
    }
    if (hasUndoneChildren && !isDone) {
      return MemStatus.undoneParent;
    }
    return MemStatus.doneable;
  }
}
