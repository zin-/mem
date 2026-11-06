import 'package:mem/features/mems/mem_entity.dart';

class MemListFilterValue {
  final bool showNotArchived;
  final bool showArchived;
  final bool showNotDone;
  final bool showDone;

  const MemListFilterValue({
    this.showNotArchived = true,
    this.showArchived = false,
    this.showNotDone = true,
    this.showDone = false,
  });

  bool? get archived => showNotArchived == showArchived ? null : showArchived;

  bool? get done => showNotDone == showDone ? null : showDone;

  bool includes(MemEntity mem) =>
      _matches(archived, mem.isArchived) && _matches(done, mem.doneAt != null);

  MemListFilterValue copyWith({
    bool? showNotArchived,
    bool? showArchived,
    bool? showNotDone,
    bool? showDone,
  }) =>
      MemListFilterValue(
        showNotArchived: showNotArchived ?? this.showNotArchived,
        showArchived: showArchived ?? this.showArchived,
        showNotDone: showNotDone ?? this.showNotDone,
        showDone: showDone ?? this.showDone,
      );

  @override
  bool operator ==(Object other) =>
      other is MemListFilterValue &&
      showNotArchived == other.showNotArchived &&
      showArchived == other.showArchived &&
      showNotDone == other.showNotDone &&
      showDone == other.showDone;

  @override
  int get hashCode => Object.hash(
        showNotArchived,
        showArchived,
        showNotDone,
        showDone,
      );

  @override
  String toString() => {
        'showNotArchived': showNotArchived,
        'showArchived': showArchived,
        'showNotDone': showNotDone,
        'showDone': showDone,
      }.toString();
}

bool _matches(bool? expected, bool actual) =>
    expected == null || expected == actual;
