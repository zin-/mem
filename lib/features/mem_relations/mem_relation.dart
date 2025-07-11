enum MemRelationType {
  prePost,
}

abstract class MemRelation {
  final int sourceMemId;
  final int targetMemId;
  final MemRelationType type;
  final int value;

  MemRelation(this.sourceMemId, this.targetMemId, this.type, this.value);

  factory MemRelation.by(
    int sourceMemId,
    int targetMemId,
    MemRelationType type,
    int value,
  ) =>
      MemRelationType.prePost == type
          ? PrePostMemRelation(sourceMemId, targetMemId, value)
          : throw UnimplementedError(); // coverage:ignore-line
}

class PrePostMemRelation extends MemRelation {
  PrePostMemRelation(int sourceMemId, int targetMemId, int value)
      : super(sourceMemId, targetMemId, MemRelationType.prePost, value);
}
