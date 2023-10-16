import 'package:mem/framework/entity.dart';
import 'package:mem/repositories/conditions/conditions.dart';

/// # Repositoryとは
///
/// システムから外部データを扱う
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
abstract class Repository<E extends Entity> {
  receive(E entity);
}

abstract class RepositoryV2<E extends EntityV2, Payload> {
  Future<Payload> receive(Payload payload);

  Future<List<Payload>> ship(Condition condition);

  Future<Payload> shipById(dynamic id);

  Future<Payload> replace(Payload payload);

  Future<Payload> archive(Payload payload);

  Future<Payload> unarchive(Payload payload);

  Future<List<Payload>> waste(Condition condition);

  Future<Payload> wasteById(dynamic id);
}
