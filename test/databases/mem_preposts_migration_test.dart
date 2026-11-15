import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem;

void main() {
  test('onUpgrade from 4 to 5 copies prePost rows into mem_preposts', () async {
    final db = AppDatabase.memory();
    await Migrator(db).createAll();
    await db.customStatement('DROP TABLE mem_preposts');
    await db.customStatement('''
CREATE TABLE mem_relations (
  created_at INTEGER NOT NULL,
  updated_at INTEGER NULL,
  archived_at INTEGER NULL,
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  source_mem_id INTEGER NOT NULL REFERENCES mems (id),
  target_mem_id INTEGER NOT NULL REFERENCES mems (id),
  type TEXT NOT NULL,
  value INTEGER NULL
)
''');

    final createdAt = DateTime(2024, 6, 3, 12);
    final updatedAt = DateTime(2024, 6, 4, 8);
    final archivedAt = DateTime(2024, 6, 5, 9);
    final source = await db.into(db.mems).insertReturning(
          MemsCompanion.insert(name: 'source', createdAt: createdAt),
        );
    final target = await db.into(db.mems).insertReturning(
          MemsCompanion.insert(name: 'target', createdAt: createdAt),
        );

    final prePostId = await db.customInsert(
      '''
INSERT INTO mem_relations (
  source_mem_id,
  target_mem_id,
  type,
  value,
  created_at,
  updated_at,
  archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?)
''',
      variables: [
        Variable.withInt(source.id),
        Variable.withInt(target.id),
        Variable.withString('prePost'),
        Variable.withInt(15),
        Variable.withDateTime(createdAt),
        Variable.withDateTime(updatedAt),
        Variable.withDateTime(archivedAt),
      ],
    );
    await db.customInsert(
      '''
INSERT INTO mem_relations (
  source_mem_id,
  target_mem_id,
  type,
  value,
  created_at
) VALUES (?, ?, ?, ?, ?)
''',
      variables: [
        Variable.withInt(source.id),
        Variable.withInt(target.id),
        Variable.withString('other'),
        Variable.withInt(99),
        Variable.withDateTime(createdAt),
      ],
    );

    await db.migration.onUpgrade(Migrator(db), 4, 5);

    final rows = await db.select(db.memPrePosts).get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.id, prePostId);
    expect(row.sourceMemId, source.id);
    expect(row.targetMemId, target.id);
    expect(row.minutes, 15);
    expect(row.createdAt, createdAt);
    expect(row.updatedAt, updatedAt);
    expect(row.archivedAt, archivedAt);

    final oldTable = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'mem_relations'",
        )
        .get();
    expect(oldTable, isEmpty);
    await db.close();
  });
}
