import 'package:mem/settings/key.dart';

class Preference<T> extends KeyWithValue<PreferenceKey<T>, T?> {
  Preference(super.key, super.value);
}

abstract class ExEntity {}

abstract class KeyWithValue<Key, Value> extends ExEntity {
  final Key key;
  final Value value;

  KeyWithValue(this.key, this.value);

  Map<String, dynamic> _toMap() => {
        "key": key,
        "value": value,
      };

  @override
  String toString() => _toMap().toString();
}
