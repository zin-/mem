import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/load_child_spec.dart';

void main() {
  group('LoadChildSpec.resolveFkToParent', () {
    test('single implicit FK to parent', () {
      final fk = LoadChildSpec.resolveFkToParent(
        defTableMemItems,
        defTableMems,
        null,
      );
      expect(fk.parentTableDefinition.name, defTableMems.name);
    });

    test('multiple FKs without explicit throws', () {
      expect(
        () => LoadChildSpec.resolveFkToParent(
          defTableMemRelations,
          defTableMems,
          null,
        ),
        throwsArgumentError,
      );
    });

    test('explicit FK for mem_relations source', () {
      final fk = LoadChildSpec.resolveFkToParent(
        defTableMemRelations,
        defTableMems,
        defFkMemRelationsSourceMemId,
      );
      expect(fk.name, 'source_mems_id');
    });

    test('explicit FK parent mismatch throws', () {
      expect(
        () => LoadChildSpec.resolveFkToParent(
          defTableMemItems,
          defTableMemRelations,
          defFkMemItemsMemId,
        ),
        throwsArgumentError,
      );
    });
  });
}
