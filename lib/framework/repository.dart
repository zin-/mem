import 'package:mem/framework/entity.dart';
import 'package:mem/framework/entity_v3.dart';
import 'package:mem/repositories/conditions/conditions.dart';
import 'package:mem/repositories/entity.dart';

/// # Repositoryとは
/// 外部データとの連携を行なう
///
/// ## 外部データとは
/// ## 連携とは
abstract class Repository<E extends Entity> {}

/// # Repositoryの役割とは
/// データを扱う
///
/// ここでの"扱う"とは、受け取ったデータを他システムへ連携したり、条件からデータを取得したりすること
///
/// # 検討
/// ## データの変換をどこで行うか
/// 自システムで扱うデータと他システムに渡すデータは形式が異なることが多いためどこかで変換が必要
/// ~~repositoryに渡す時点で変換されているべき？~~
/// repositoryで変換する
///
/// # ライブラリをどう扱うか
/// 殆どの場合、他システムへのアクセスはライブラリを通じて行うことになる
///
/// ライブラリのラッパーを定義する場合、repositoryの役割は何になるか？
/// データの変換してラッパーを呼び出すこと
///
/// ライブラリの形式に合わせるのはラッパーの役割なのでデータの変換をどこまでやるかという話はあるかも
///
/// # テストをどうするか
/// 他システムと連携するため、基本的にはSmall testではカバーできない
///
/// 例外的にコアなフレームワーク・ライブラリ（dartやflutter）でモックが用意されていて、
/// Small testに収まる場合もある（MethodChannelなど
///
/// 加えて、ライブラリを正しく使えているかのテストは利用者側で行う必要がある
abstract class RepositoryV3<Payload extends EntityV3, Result> {
  // FIXME rename payload
  //  Repositoryが扱うものとしてはPayloadもいい名前だけど
  //  受け取るのも払い出すのもPayloadなのでもっと詳細な名前にしたい
  //  -> entity?
  //    DatabaseRepositoryにおいてはentityでもなさそう
  Result receive(Payload payload);
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