import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service_v2.dart';

const _jsonEncoderIndent = '  ';

class ValueStateNotifier<T> extends StateNotifier<T> {
  ValueStateNotifier(super.state);

  T updatedBy(T value) => v(
        () {
          return state = value;
        },
        {'state': state, 'value': value},
      );

// coverage:ignore-start
  @override
  String toString() {
    String content;
    if (state is Map || state is Iterable) {
      final encoder = JsonEncoder.withIndent(
        _jsonEncoderIndent,
        (object) => object.toString(),
      );
      content = encoder.convert(state);
    } else {
      content = state.toString();
    }

    return 'ValueStateNotifier: $content';
  }
// coverage:ignore-end
}
