/// # Entityとは
///
/// システムから見た外部データを表す
// # 語源
//
// 「存在するもの」、「実体」
mixin Entity {
  Map<String, dynamic> get toMap;

  @override
  String toString() => "${super.toString()}: $toMap";

  @override
  int get hashCode => toMap.entries.fold(
        0,
        (value, element) =>
            value ^ element.key.hashCode ^ element.value.hashCode,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType && hashCode == other.hashCode);
}

mixin Copyable<T> on Entity {
  T copiedWith();
}
// memo
// - view, domain, dataのそれぞれの領域で似た内容でも型が変わることになるはず
// これをしっかりと定義したい
// 具体的にはview->domain->dataの順で厳しくなっていくはず
// e.g.
//  view領域では表示の問題でnullableだが、
//  domain領域では、nullの場合はそもそも実行する必要がないはずなのでnot nullになっている
//  data領域ではさらに厳しく、データとして存在しているはずのものしかなくなるのでidなどの情報が付与されているはず
//  など
