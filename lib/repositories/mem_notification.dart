import 'package:mem/core/mem_notification.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

class SavedMemNotification extends MemNotification
    with SavedDatabaseTupleMixinV1<int> {
  @override
  int get memId => super.memId as int;

  SavedMemNotification(super.memId, super.type, super.time, super.message);

  @override
  SavedMemNotification copiedWith({
    int Function()? memId,
    int? Function()? time,
    String Function()? message,
  }) =>
      SavedMemNotification(
        memId == null ? this.memId : memId(),
        type,
        time == null ? this.time : time(),
        message == null ? this.message : message(),
      )..copiedFrom(this);
}
