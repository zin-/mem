import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/settings/preference/preference_key.dart';

class PreferenceEntity<VALUE>
    with Entity, KeyWithValue<PreferenceKey<VALUE>, VALUE?> {
  PreferenceEntity(PreferenceKey<VALUE> key, VALUE? value) {
    this.key = key;
    this.value = value;
  }
}
