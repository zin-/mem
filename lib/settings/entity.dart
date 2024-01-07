class PreferenceKey {
  final String value;
  final Type type;

  PreferenceKey(this.value, this.type);
}

class Preference extends KeyWithValue<String, Object?> {
  Preference(super.key, super.value);
}

abstract class ExEntity {}

abstract class KeyWithValue<Key, Value> extends ExEntity {
  final Key key;
  final Value value;

  KeyWithValue(this.key, this.value);

  Map<String, Object?> _toMap() => {
        "key": key,
        "value": value,
      };

  @override
  String toString() => _toMap().toString();
}
