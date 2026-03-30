import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/order_by.dart';

class LoadChildSpec {
  final TableDefinition table;
  final ForeignKeyDefinition? fkToParent;
  final Condition? condition;
  final String resultKey;
  final List<OrderBy>? orderBy;
  final int? limit;
  final int? offset;

  LoadChildSpec({
    required this.table,
    this.fkToParent,
    this.condition,
    String? resultKey,
    this.orderBy,
    this.limit,
    this.offset,
  }) : resultKey = resultKey ?? table.name;

  bool get usesPerParentOrdering =>
      limit != null ||
      offset != null ||
      (orderBy != null && orderBy!.isNotEmpty);

  static ForeignKeyDefinition resolveFkToParent(
    TableDefinition child,
    TableDefinition parent, [
    ForeignKeyDefinition? explicit,
  ]) {
    if (explicit != null) {
      if (explicit.parentTableDefinition.name != parent.name) {
        throw ArgumentError(
          'fkToParent targets ${explicit.parentTableDefinition.name}, '
          'expected parent ${parent.name}',
        );
      }
      return explicit;
    }
    final candidates = child.foreignKeyDefinitions
        .where((fk) => fk.parentTableDefinition.name == parent.name)
        .toList();
    if (candidates.isEmpty) {
      throw ArgumentError(
        'No FK from ${child.name} to ${parent.name}; pass fkToParent.',
      );
    }
    if (candidates.length > 1) {
      throw ArgumentError(
        'Multiple FKs from ${child.name} to ${parent.name}; pass fkToParent.',
      );
    }
    return candidates.single;
  }
}
