import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';

const _jsonEncoderIndent = '  ';

class ValueStateNotifier<StateT> extends StateNotifier<StateT> {
  ValueStateNotifier(
    super.state, {
    void Function(
      StateT current,
      ValueStateNotifier<StateT> notifier,
    )? initializer,
  }) {
    if (initializer != null) {
      if (mounted) {
        initializer.call(state, this);
      } else {
// coverage:ignore-start
        warn("${super.toString()}. No update.");
// coverage:ignore-end
      }
    }
  }

  StateT updatedBy(StateT value) => v(
        () {
          state.toString() == value.toString()
              ? verbose(
                  "No update. Same value: ${{
                    "state": state,
                    "value": value,
                  }}",
                )
              : state = value;

          return state;
        },
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
