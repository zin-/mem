class MemPrePost {
  final int sourceMemId;
  final int targetMemId;
  final int minutes;

  MemPrePost._(this.sourceMemId, this.targetMemId, this.minutes);

  static MemPrePost? of({
    required int? sourceMemId,
    required int? targetMemId,
    required int? minutes,
  }) {
    if (sourceMemId == null || targetMemId == null || minutes == null) {
      return null;
    }
    return MemPrePost._(sourceMemId, targetMemId, minutes);
  }

  MemPrePost withSourceMemId(int sourceMemId) =>
      MemPrePost._(sourceMemId, targetMemId, minutes);
}
