import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';

const _jsonEncoderIndent = '  ';

class ValueStateNotifier<StateT> extends StateNotifier<StateT> {
  ValueStateNotifier(
    super.state, {
    Future<StateT>? initialFuture,
  }) {
    initialFuture?.then(
      (value) => v(
        () => updatedBy(value),
        value,
      ),
    );
  }

  StateT updatedBy(StateT value) => v(
        () => state = value,
        {'current': state, 'updating': value},
      );

// coverage:ignore-start
  @override
  String toString() {
    String content;
    if (mounted) {
      if (state is Map || state is Iterable) {
        final encoder = JsonEncoder.withIndent(
          _jsonEncoderIndent,
          (object) => object.toString(),
        );
        content = encoder.convert(state);
      } else {
        content = state.toString();
      }

      return "${super.toString()}: $content";
    } else {
      return "${super.toString()} is disposed";
    }
  }
// coverage:ignore-end
}
