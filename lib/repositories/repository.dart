import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';

// Repositoryというのは保存方法を隠蔽するためのもの
// 画一的な変換までは行う
// 外からみたときの型は型変数で渡す
// 保存方法にかかわる変数は初期化で渡す
abstract class DatabaseTableRepository<Entity> {
  // FIXME DatabaseTableEntityを実装してるやつだけにげ限定する
  Table table; // FIXME be private

  DatabaseTableRepository(this.table);
}

abstract class DatabaseTableEntity {
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  DatabaseTableEntity({
    required this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });
}

final defaultColumnDefinitions = [
  DefC('createdAt', TypeC.datetime),
  DefC('updatedAt', TypeC.datetime, notNull: false),
  DefC('archivedAt', TypeC.datetime, notNull: false),
];
