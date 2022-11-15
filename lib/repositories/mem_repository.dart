import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger/api.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';

const memNameColumnName = 'name';
const memDoneAtColumnName = 'doneAt';
const memNotifyOnColumnName = 'notifyOn';
const memNotifyAtColumnName = 'notifyAt';

final memTableDefinition = DefT(
  'mems',
  [
    DefPK(idColumnName, TypeC.integer, autoincrement: true),
    DefC(memNameColumnName, TypeC.text),
    DefC(memDoneAtColumnName, TypeC.datetime, notNull: false),
    DefC(memNotifyOnColumnName, TypeC.datetime, notNull: false),
    DefC(memNotifyAtColumnName, TypeC.datetime, notNull: false),
    ...defaultColumnDefinitions
  ],
);

class MemEntity extends DatabaseTupleEntity {
  String name;
  DateTime? doneAt;
  DateTime? notifyOn;
  DateTime? notifyAt;

  MemEntity({
    required this.name,
    this.doneAt,
    this.notifyOn,
    this.notifyAt,
    required int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  @override
  MemEntity.fromMap(Map<String, dynamic> valueMap)
      : name = valueMap[memNameColumnName],
        doneAt = valueMap[memDoneAtColumnName],
        notifyOn = valueMap[memNotifyOnColumnName],
        notifyAt = valueMap[memNotifyAtColumnName],
        super.fromMap(valueMap);

  @override
  Map<String, dynamic> toMap() => {
        memNameColumnName: name,
        memDoneAtColumnName: doneAt,
        memNotifyOnColumnName: notifyOn,
        memNotifyAtColumnName: notifyAt,
      }..addAll(super.toMap());
}

class MemRepository extends DatabaseTupleRepository<MemEntity> {
  @override
  Future<List<MemEntity>> ship({
    Map<String, dynamic>? whereMap,
    bool? archive,
    bool? done,
  }) =>
      v(
        {
          'whereMap': whereMap,
          'archive': archive,
          'done': done,
        },
        () async {
          return super.ship(
              whereMap: whereMap ?? {}
                ..addAll(buildNullableWhere(
                  archivedAtColumnName,
                  archive,
                ))
                ..addAll(buildNullableWhere(
                  memDoneAtColumnName,
                  done,
                )));
        },
      );

  @override
  MemEntity fromMap(Map<String, dynamic> valueMap) =>
      MemEntity.fromMap(valueMap);

  MemRepository._(super.table);

  static MemRepository? _instance;

  factory MemRepository([Table? memTable]) {
    var tmp = _instance;
    if (tmp == null) {
      if (memTable == null) {
        throw Exception('Call initialize'); // coverage:ignore-line
      }
      tmp = MemRepository._(memTable);
      _instance = tmp;
    }
    return tmp;
  }

  static void reset(MemRepository? memRepository) {
    _instance = memRepository;
  }
}
