/// # Entityとは
///
/// システムが扱うデータとしての実体を表現する
// # 語源
//
// 「存在するもの」、「実体」
// # Domainとの違い
// Domainと違い、Entityは具体的なデータとの繋がりがあるためいくつかの制約を持ち、持たせることができる
// 具体的には、そのデータを一意に定める識別子(id)を持ったり、作成日時などのmetadataを持つ
mixin EntityV1<VALUE> {
  late VALUE value;

  Map<String, Object?> get toMap;

  EntityV1<VALUE> updatedWith(VALUE Function(VALUE v) update);

  @override
  String toString() => "${super.toString()}: $toMap";

// @override
// int get hashCode => toMap.entries.fold(
//       1,
//       (p, e) => p ^ e.key.hashCode ^ e.value.hashCode,
//     );
//
// @override
// bool operator ==(Object other) =>
//     identical(this, other) ||
//     (runtimeType == other.runtimeType && hashCode == other.hashCode);
}

final Map<Type, Set<Type>> entityChildrenRelation = {};
// memo
// - view, domain, dataのそれぞれの領域で似た内容でも型が変わることになるはず
// これをしっかりと定義したい
// 具体的にはview->domain->dataの順で厳しくなっていくはず
// e.g.
//  view領域では表示の問題でnullableだが、
//  domain領域では、nullの場合はそもそも実行する必要がないはずなのでnot nullになっている
//  data領域ではさらに厳しく、データとして存在しているはずのものしかなくなるのでidなどの情報が付与されているはず
//  など

// Entityを定義したくなるが、保存された際に同一性が発生するためより抽象的で何も振る舞いを持たないEntityを定義する意味がない
abstract interface class SavedEntity<ID> {
  ID get id;
}
