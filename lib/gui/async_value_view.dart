import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/i/api.dart';

const stackTraceFontSize = 16.0;

class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> _asyncValue;
  final Widget Function(T data) _viewBuilder;

  const AsyncValueView(this._asyncValue, this._viewBuilder, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'_asyncValue': _asyncValue},
        () => _asyncValue.when(
          loading: () => const CircularProgressIndicator(),
          data: (data) => _viewBuilder(data),
          error: (error, stackTrace) => SingleChildScrollView(
            child: Column(
              children: [
                Text(error.toString()),
                Text(
                  stackTrace.toString(),
                  style: const TextStyle(fontSize: stackTraceFontSize),
                ),
              ],
            ),
          ),
        ),
      );
}
