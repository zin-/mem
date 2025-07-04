enum MemRelationType {
  prePost,
}

abstract class MemRelation {
  final int sourceMemId;
  final int targetMemId;
  final MemRelationType type;

  MemRelation(this.sourceMemId, this.targetMemId, this.type);

  factory MemRelation.by(
    int sourceMemId,
    int targetMemId,
    MemRelationType type,
  ) =>
      MemRelationType.prePost == type
          ? PrePostMemRelation(sourceMemId, targetMemId)
          : throw UnimplementedError(); // coverage:ignore-line
}

class PrePostMemRelation extends MemRelation {
  PrePostMemRelation(int sourceMemId, int targetMemId)
      : super(sourceMemId, targetMemId, MemRelationType.prePost);
}
