import 'package:mem/framework/database/definition/column/column_definition.dart';

import 'condition/conditions.dart';
import 'entity.dart';

/// # Repositoryとは
///
/// 集約（Aggregate）単位での永続化・取得を担当する
// ## 語源
//
// 「倉庫」、「貯蔵庫」、「資源のありか」
//
// IT分野においては、データ・コード・ドキュメントなどの情報を保管・格納する場所として用いる
//
// ## 関数名について
//
// 一般的には`getById(id)`, `update(entity)`などとされる場合が多いが、ここでは採用しない
//
// ### 理由
// オブジェクト指向プログラミングにおける原理的な解釈において誤りである
//  「倉庫」が`get`（得る）ことはあるだろうか？
//  抽象的には得ると捉える事もできるだろうが、では`update`（更新する）ことはあるだろうか？
//  更新することはないように感じる
//  よって、ここでは`receive`（受け取る）、`replace`（置き換える）などの荷物や事物を扱う際の単語を採用する
abstract class Repository<ENTITYV1 extends EntityV1, DOMAIN> {
  static final Map<Type, Repository> _allRepositories = {};

  Repository() {
    _allRepositories[ENTITYV1] ??= this;

    entityChildrenRelation[ENTITYV1]?.forEach(
      (childEntity) => childRepositories[childEntity] ??= {
        _allRepositories[childEntity]: null
      },
    );
  }

  final Map<Type, Map<Repository?, Iterable<ColumnDefinition>?>>
      childRepositories = {};

  waste({Condition? condition});
}
