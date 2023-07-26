// 取り扱うデータを定義する
// # 検討
// ## 自システム寄りか他システム寄りか
abstract class EntityV3 {}

// memo
// - view, domain, dataのそれぞれの領域で似た内容でも型が変わることになるはず
// これをしっかりと定義したい
// 具体的にはview->domain->dataの順で厳しくなっていくはず
// e.g.
//  view領域では表示の問題でnullableだが、
//  domain領域では、nullの場合はそもそも実行する必要がないはずなのでnot nullになっている
//  data領域ではさらに厳しく、データとして存在しているはずのものしかなくなるのでidなどの情報が付与されているはず
//  など
