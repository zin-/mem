import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';

class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> _asyncValue;
  final Widget Function(T value) _viewBuilder;
  final Widget Function() _loadingViewBuilder;
  final Widget Function(Object error, StackTrace? stackTrace) _errorViewBuilder;

  AsyncValueView(
    this._asyncValue,
    this._viewBuilder, {
    Widget Function()? loadingViewBuilder,
    Widget Function(Object error, StackTrace? stackTrace)? errorViewBuilder,
    Key? key,
  })  : _loadingViewBuilder =
            loadingViewBuilder ?? (() => const CircularProgressIndicator()),
        _errorViewBuilder = errorViewBuilder ??
            ((error, stackTrace) => SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(error.toString()),
                      // TODO show error details
                      // ...stackTrace
                      //     .toString()
                      //     .split('\n')
                      //     .slice(0, 5)
                      //     .map((element) => Text(element))
                    ],
                  ),
                )),
        super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {'asyncValue': _asyncValue},
        () {
          return _asyncValue.when(
            data: _viewBuilder,
            loading: _loadingViewBuilder,
            error: _errorViewBuilder,
          );
        },
      );
}
