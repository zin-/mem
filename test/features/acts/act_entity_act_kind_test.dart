import 'package:flutter_test/flutter_test.dart';
import '../../entity_factories.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

void main() {
  group('ActEntity act_kind', () {
    test('SavedActEntityV1 reads skipped from entity factory', () {
      final entity = savedAct(
        id: 1,
        memId: 2,
        start: DateTime(2024, 6, 1, 10),
        startIsAllDay: false,
        end: DateTime(2024, 6, 1, 11),
        endIsAllDay: false,
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        actKind: ActKind.skipped,
      );

      expect(entity.value.actKind, ActKind.skipped);
      expect(entity.value.isSkipped, isTrue);
      expect(entity.toMap['actKind'], 'skipped');
    });

    test('SavedActEntityV1.toEntityV2 preserves act_kind', () {
      final entity = savedAct(
        id: 7,
        memId: 8,
        start: DateTime(2024, 6, 4, 10),
        startIsAllDay: false,
        end: DateTime(2024, 6, 4, 11),
        endIsAllDay: false,
        createdAt: DateTime(2024, 6, 4),
        updatedAt: DateTime(2024, 6, 4),
        actKind: ActKind.skipped,
      );

      expect(entity.toEntityV2().actKind, ActKind.skipped);
    });

    test('ActEntity.fromTuple drift row includes act_kind', () {
      final entity = ActEntity.fromTuple(_FakeActRow(
        id: 5,
        memId: 6,
        start: DateTime(2024, 6, 3, 10),
        startIsAllDay: false,
        end: DateTime(2024, 6, 3, 11),
        endIsAllDay: false,
        pausedAt: null,
        actKind: 'skipped',
        createdAt: DateTime(2024, 6, 3),
        updatedAt: DateTime(2024, 6, 3),
        archivedAt: null,
      ));

      expect(entity.actKind, ActKind.skipped);
    });

    test('convertIntoActsInsertable persists act_kind', () async {
      final db = AppDatabase.memory();
      final mem = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(
              name: 'm',
              createdAt: DateTime(2024, 6, 1),
            ),
          );
      final act = Act.by(
        mem.id,
        startWhen: DateAndTime(2024, 6, 1, 10),
        endWhen: DateAndTime(2024, 6, 1, 11),
        completionKind: ActKind.skipped,
      );

      await db.into(db.acts).insert(
            convertIntoActsInsertable(act, createdAt: DateTime(2024, 6, 1)),
          );

      final row = await db.select(db.acts).getSingle();
      expect(row.actKind, ActKind.skipped.name);
      await db.close();
    });
  });
}

class _FakeActRow {
  final int id;
  final int memId;
  final DateTime? start;
  final bool? startIsAllDay;
  final DateTime? end;
  final bool? endIsAllDay;
  final DateTime? pausedAt;
  final String? actKind;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  _FakeActRow({
    required this.id,
    required this.memId,
    required this.start,
    required this.startIsAllDay,
    required this.end,
    required this.endIsAllDay,
    required this.pausedAt,
    required this.actKind,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });
}
