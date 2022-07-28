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
      // archivedAt: (map['archivedAt'] is DateTime?)
      //     ? map['archivedAt']
      //     : DateTime.parse(map['archivedAt']),
      archivedAt: null,
    );
  }

  @override
  String toString() => toMap().toString();
}
