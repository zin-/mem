import 'package:mem/frame_work/accessor.dart';
import 'package:mem/frame_work/entity_v3.dart';

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
abstract class RepositoryV3<Payload extends EntityV3, Result> extends Accessor {
  Result receive(Payload payload);
}
