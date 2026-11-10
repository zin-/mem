class MemDoneEdit {
  final void Function(bool? value) onChanged;

  MemDoneEdit._(this.onChanged);

  static MemDoneEdit? of({
    required bool hasUndoneChildren,
    required bool isDone,
    required void Function(bool? value) onChanged,
  }) {
    if (hasUndoneChildren && !isDone) return null;
    return MemDoneEdit._(onChanged);
  }
}
