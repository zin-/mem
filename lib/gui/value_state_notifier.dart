// import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// const _jsonEncoderIndent = '  ';

class ValueStateNotifier<T> extends StateNotifier<T> {
  ValueStateNotifier(super.state);

  // TODO performance 値が変わっていたら通知する形にしたい
  T updatedBy(T value) => state = value;

// FIXME coverage
// @override
// String toString() {
//   String content;
//   if (state is Map || state is Iterable) {
//     final encoder = JsonEncoder.withIndent(
//       _jsonEncoderIndent,
//       (object) => object.toString(),
//     );
//     content = encoder.convert(state);
//   } else {
//     content = state.toString();
//   }
//
//   return 'ValueStateNotifier: $content';
// }
}
