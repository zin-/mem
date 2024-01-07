class PreferenceKey<T> {
  final String value;
  final Type type;

  PreferenceKey(this.value, this.type);

  @override
  String toString() => value;
}

class Preference<T> extends KeyWithValue<PreferenceKey<T>, Object?> {
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
