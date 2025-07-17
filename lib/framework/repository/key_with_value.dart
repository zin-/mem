import 'package:mem/framework/repository/entity.dart';

// FIXME IdWithValueの方が命名として適切なのでは？
mixin KeyWithValue<KEY, VALUE> on Entity<VALUE> {
  late final KEY key;

  @override
  Map<String, dynamic> get toMap => {'key': key, 'value': value};
}
