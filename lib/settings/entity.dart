import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/settings/key.dart';

class Preference<T> extends KeyWithValue<PreferenceKey<T>, T?> {
  Preference(super.key, super.value);
}
