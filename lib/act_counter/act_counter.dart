import 'package:mem/core/mem.dart';
import 'package:mem/repositories/i/_entity_v2.dart';

class ActCounter extends EntityV2 {
  final MemId memId;
  final int? actCount;
  final DateTime? lastUpdatedAt;
  final String? name;

  ActCounter(this.memId, {this.actCount, this.lastUpdatedAt, this.name});

  @override
  String toString() => '{'
      ' memId: $memId'
      ', actCount: $actCount'
      ', lastUpdatedAt: $lastUpdatedAt'
      ', name: $name'
      ' }';
}
