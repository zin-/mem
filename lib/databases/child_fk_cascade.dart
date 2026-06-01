import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart';

const cascadeChunkSize = 900;

Future<void> wasteChildRowsReferencingMemIds(
  AppDatabase db,
  List<int> memIds,
) async {
  if (memIds.isEmpty) return;

  for (var i = 0; i < memIds.length; i += cascadeChunkSize) {
    final chunk = memIds.sublist(
      i,
      math.min(i + cascadeChunkSize, memIds.length),
    );
    await (db.delete(db.memItems)..where((t) => t.memId.isIn(chunk))).go();
    await (db.delete(db.acts)..where((t) => t.memId.isIn(chunk))).go();
    await (db.delete(db.memRepeatedNotifications)
          ..where((t) => t.memId.isIn(chunk)))
        .go();
    await (db.delete(db.targets)..where((t) => t.memId.isIn(chunk))).go();
    await (db.delete(db.memRelations)
          ..where(
            (t) => t.sourceMemId.isIn(chunk) | t.targetMemId.isIn(chunk),
          ))
        .go();
  }
}
