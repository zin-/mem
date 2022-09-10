import 'package:mem/database/database.dart';

// Repositoryというのは保存方法を隠蔽するためのもの
// 画一的な変換までは行う
// 外からみたときの型は型変数で渡す
// 保存方法にかかわる変数は初期化で渡す
abstract class DatabaseTableRepository<Entity> {
  Table table; // TODO be private

  DatabaseTableRepository(this.table);
}

abstract class DatabaseTableEntity {}
