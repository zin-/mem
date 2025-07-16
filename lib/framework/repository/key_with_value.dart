import 'package:mem/framework/repository/entity.dart';

// FIXME IdWithValueの方が命名として適切なのでは？
mixin KeyWithValue<KEY, VALUE> on EntityV1 {
  late final KEY key;
  late final VALUE value;

  @override
  Map<String, dynamic> get toMap => {'key': key, 'value': value};
}
