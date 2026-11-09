import 'package:mem/features/mems/mem_notify_at.dart';

class MemListAt {
  final DateTime at;

  MemListAt._(this.at);

  static MemListAt? of(MemNotifyAt? notifyAt) {
    if (notifyAt == null) return null;
    return MemListAt._(notifyAt.at);
  }
}
