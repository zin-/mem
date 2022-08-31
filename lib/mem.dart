// TODO 必須の項目の変数名を定数化する（createdAtとか）
class Mem {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  const Mem({
    required this.id,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  bool isSaved() => isSavedMap(toMap());

  static bool isSavedMap(Map<String, dynamic> memMap) =>
      memMap['id'] != null && memMap['createdAt'] != null;

  static bool isArchivedMap(Map<String, dynamic> memMap) =>
      memMap['archivedAt'] != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      };

  factory Mem.fromMap(Map<String, dynamic> map) {
    return Mem(
      id: map['id'],
      name: map['name'],
      createdAt: (map['createdAt'] is DateTime)
          ? map['createdAt']
          : DateTime.parse(map['createdAt']),
      updatedAt: (map['updatedAt'] is DateTime?)
          ? map['updatedAt']
          : DateTime.parse(map['updatedAt']),
      archivedAt: (map['archivedAt'] is DateTime?)
          ? map['archivedAt']
          : DateTime.parse(map['archivedAt']),
    );
  }

  @override
  String toString() => toMap().toString();
}
