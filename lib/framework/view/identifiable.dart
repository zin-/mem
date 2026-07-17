/// primary key を持つ view 層データの契約。
///
/// 一覧 State（`EntitiesState`）が要素を一意に識別するために利用する。
abstract interface class Identifiable<ID> {
  ID get id;
}
