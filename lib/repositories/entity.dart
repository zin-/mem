abstract class EntityV2 {
  Map<String, dynamic> toMap();

  @override
  String toString() => toMap().toString();
}
