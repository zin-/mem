import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';

const _jsonEncoderIndent = '  ';

class ValueStateNotifier<T> extends StateNotifier<T> {
  ValueStateNotifier(super.state, {Future<T>? future}) {
    future?.then((value) => v(() => updatedBy(value), value));
  }

  T updatedBy(T value) => v(
        () => state = value,
        {'current': state, 'updating': value},
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
