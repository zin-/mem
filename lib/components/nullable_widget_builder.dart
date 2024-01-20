import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

const nullableWidget = SizedBox.shrink();

class NullableWidgetBuilder {
  final Widget Function() _builder;

  NullableWidgetBuilder(this._builder);

  Widget? build() => v(
        () {
          final built = verbose(_builder());
          return built.isNullable() ? null : built;
        },
      );
}

extension on Widget {
  bool isNullable() => v(
        () => this == nullableWidget,
      );
}
