import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mems/list/filter_value.dart';

import '../../../entity_factories.dart';

void main() {
  final active = savedMem(id: 1, name: 'active');
  final archived = savedMem(
    id: 2,
    name: 'archived',
    archivedAt: DateTime(2024, 1, 1),
  );
  final done = savedMem(
    id: 3,
    name: 'done',
    doneAt: DateTime(2024, 1, 2),
  );
  final archivedDone = savedMem(
    id: 4,
    name: 'archived done',
    doneAt: DateTime(2024, 1, 2),
    archivedAt: DateTime(2024, 1, 1),
  );

  group('MemListFilterValue', () {
    test('default keeps unarchived and undone', () {
      const filter = MemListFilterValue();

      expect(filter.showNotArchived, isTrue);
      expect(filter.showArchived, isFalse);
      expect(filter.showNotDone, isTrue);
      expect(filter.showDone, isFalse);
      expect(filter.archived, isFalse);
      expect(filter.done, isFalse);
      expect(filter.includes(active), isTrue);
      expect(filter.includes(archived), isFalse);
      expect(filter.includes(done), isFalse);
      expect(filter.includes(archivedDone), isFalse);
    });

    test('same switches leave that axis unfiltered', () {
      const archivesOn = MemListFilterValue(
        showNotArchived: true,
        showArchived: true,
      );
      const archivesOff = MemListFilterValue(
        showNotArchived: false,
        showArchived: false,
      );
      const donesOn = MemListFilterValue(
        showNotDone: true,
        showDone: true,
      );
      const open = MemListFilterValue(
        showNotArchived: true,
        showArchived: true,
        showNotDone: true,
        showDone: true,
      );

      expect(archivesOn.archived, isNull);
      expect(archivesOff.archived, isNull);
      expect(archivesOn, isNot(archivesOff));
      expect(archivesOn.toString(), isNot(archivesOff.toString()));
      expect(archivesOn.includes(active), isTrue);
      expect(archivesOn.includes(archived), isTrue);
      expect(archivesOn.includes(done), isFalse);

      expect(donesOn.done, isNull);
      expect(donesOn.includes(active), isTrue);
      expect(donesOn.includes(done), isTrue);
      expect(donesOn.includes(archived), isFalse);

      expect(open.archived, isNull);
      expect(open.done, isNull);
      expect(open.includes(active), isTrue);
      expect(open.includes(archived), isTrue);
      expect(open.includes(done), isTrue);
      expect(open.includes(archivedDone), isTrue);
    });

    test('shown side selects archived or done mems', () {
      const archivedOnly = MemListFilterValue(
        showNotArchived: false,
        showArchived: true,
      );
      const doneOnly = MemListFilterValue(
        showNotDone: false,
        showDone: true,
      );
      const archivedAndDone = MemListFilterValue(
        showNotArchived: false,
        showArchived: true,
        showNotDone: false,
        showDone: true,
      );

      expect(archivedOnly.archived, isTrue);
      expect(archivedOnly.includes(archived), isTrue);
      expect(archivedOnly.includes(active), isFalse);
      expect(archivedOnly.includes(archivedDone), isFalse);

      expect(doneOnly.done, isTrue);
      expect(doneOnly.includes(done), isTrue);
      expect(doneOnly.includes(active), isFalse);
      expect(doneOnly.includes(archived), isFalse);

      expect(archivedAndDone.includes(archivedDone), isTrue);
      expect(archivedAndDone.includes(archived), isFalse);
      expect(archivedAndDone.includes(done), isFalse);
      expect(archivedAndDone.includes(active), isFalse);
    });

    test('copyWith keeps unspecified fields and toString follows them', () {
      const filter = MemListFilterValue();
      final updated = filter.copyWith(showArchived: true);

      expect(updated.showArchived, isTrue);
      expect(updated.showNotArchived, filter.showNotArchived);
      expect(updated.showNotDone, filter.showNotDone);
      expect(updated.showDone, filter.showDone);
      expect(updated, isNot(filter));
      expect(updated.toString(), isNot(filter.toString()));
      expect(filter.copyWith(), filter);
      expect(filter.copyWith().hashCode, filter.hashCode);
      expect(filter.copyWith().toString(), filter.toString());
    });
  });
}
