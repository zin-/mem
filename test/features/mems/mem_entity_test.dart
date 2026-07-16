import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_view_data.dart';

import '../../entity_factories.dart';

void main() {
  group('MemEntity', () {
    test('MemViewData toMap for saved mem', () {
      final period = DateAndTimePeriod(
        start: DateAndTime(2024, 1, 5, 10, 0),
        end: DateAndTime(2024, 1, 6, 11, 0),
      );
      final viewData = MemViewData(
        Mem(1, 'm', DateTime(2024, 1, 4), period),
      );

      expect(viewData.toMap, containsPair('name', 'm'));
      expect(viewData.toMap['notifyOn'], isNotNull);
      expect(viewData.toMap['endOn'], isNotNull);
      expect(viewData.isSaved, isTrue);
    });

    test('MemEntity keeps latestAct through updatedWith', () {
      final latestAct = savedAct(
        id: 5,
        memId: 10,
        start: DateTime(2024, 2, 1, 10),
        startIsAllDay: false,
        end: DateTime(2024, 2, 1, 11),
        endIsAllDay: false,
      ).value;
      final entity = MemEntity(
        10,
        'before',
        null,
        null,
        null,
        DateTime(2024, 2, 1),
        DateTime(2024, 2, 2),
        null,
        latestAct: latestAct,
      );

      expect(entity.latestAct, latestAct);
      expect(entity.id, 10);

      final updated = entity.updatedWith(
        update: (mem) => Mem(mem.id, 'after', mem.doneAt, mem.period),
      );

      expect(updated.name, 'after');
      expect(updated.latestAct, latestAct);
      expect(updated.id, 10);
    });

    test('MemViewData updatedWith updates period', () {
      final viewData = MemViewData.fromEntityV2(
        savedMem(
          id: 11,
          name: 'period-mem',
          notifyOn: DateTime(2024, 4, 1),
          notifyAt: DateTime(2024, 4, 1, 10),
          endOn: DateTime(2024, 4, 2),
          endAt: DateTime(2024, 4, 2, 18),
        ),
      );

      final newStart = DateAndTime(2024, 5, 1, 9, 0);
      final newEnd = DateAndTime(2024, 5, 3, 17, 0);
      final newPeriod = DateAndTimePeriod(start: newStart, end: newEnd);

      final updated = viewData.updatedWith(
        (mem) => Mem(mem.id, mem.name, mem.doneAt, newPeriod),
      );

      expect(updated.value.period?.start, newStart);
      expect(updated.value.period?.end, newEnd);
    });

    test('fromTuple with children and updatedWith fields', () {
      final mem = MemEntity.fromTuple(
        _FakeMemRow(
          id: 2,
          name: 'tuple',
          doneAt: DateTime(2024, 3, 1),
          notifyOn: DateTime(2024, 3, 2),
          notifyAt: DateTime(2024, 3, 2, 9),
          endOn: DateTime(2024, 3, 3),
          endAt: DateTime(2024, 3, 3, 18),
          createdAt: DateTime(2024, 3, 1),
          updatedAt: DateTime(2024, 3, 4),
          archivedAt: null,
        ),
        children: {
          'mem_items': [
            MemItemEntity(2, MemItemType.memo, 'item', 1, DateTime(2024, 3, 1), null, null),
          ],
          'mem_repeated_notifications': [
            MemNotificationEntity(
              2,
              MemNotificationType.repeat,
              600,
              'n',
              2,
              DateTime(2024, 3, 1),
              null,
              null,
            ),
          ],
          'mem_relations': [
            MemRelationEntity(
              2,
              3,
              MemRelationType.prePost,
              10,
              3,
              DateTime(2024, 3, 1),
              null,
              null,
            ),
          ],
          'latest_act': [
            savedAct(
              id: 7,
              memId: 2,
              start: DateTime(2024, 3, 1, 8),
              startIsAllDay: false,
              end: DateTime(2024, 3, 1, 9),
              endIsAllDay: false,
            ).toEntityV2(),
          ],
        },
      );

      expect(mem.name, 'tuple');
      expect(mem.items, hasLength(1));
      expect(mem.repeatedNotifications, hasLength(1));
      expect(mem.memRelations, hasLength(1));
      expect(mem.latestAct, isNotNull);
      expect(mem.period, isNotNull);
      expect(mem.toDomain().latestAct, isNotNull);

      final changed = mem.updatedWith(
        update: (m) => Mem(m.id, 'changed', m.doneAt, m.period),
        items: () => [],
        repeatedNotifications: () => [],
        memRelations: () => [],
        latestAct: () => null,
        updatedAt: () => DateTime(2024, 3, 10),
        archivedAt: () => DateTime(2024, 3, 11),
      );
      expect(changed.name, 'changed');
      expect(changed.items, isEmpty);
      expect(changed.repeatedNotifications, isEmpty);
      expect(changed.memRelations, isEmpty);
      expect(changed.latestAct, isNull);
      expect(changed.updatedAt, DateTime(2024, 3, 10));
      expect(changed.archivedAt, DateTime(2024, 3, 11));
    });

    test('fromTuple without period fields creates null period', () {
      final mem = MemEntity.fromTuple(
        _FakeMemRow(
          id: 3,
          name: 'nop',
          doneAt: null,
          notifyOn: null,
          notifyAt: null,
          endOn: null,
          endAt: null,
          createdAt: DateTime(2024, 4, 1),
          updatedAt: null,
          archivedAt: null,
        ),
      );
      expect(mem.period, isNull);
    });
  });
}

class _FakeMemRow {
  final int id;
  final String name;
  final DateTime? doneAt;
  final DateTime? notifyOn;
  final DateTime? notifyAt;
  final DateTime? endOn;
  final DateTime? endAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  _FakeMemRow({
    required this.id,
    required this.name,
    required this.doneAt,
    required this.notifyOn,
    required this.notifyAt,
    required this.endOn,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });
}
