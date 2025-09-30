import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mem/features/logger/log_service.dart';

class AsyncValueView<D> extends ConsumerWidget {
  final ProviderListenable<AsyncValue<D>> _asyncValueProvider;
  final Widget Function(D loaded) _builder;

  const AsyncValueView(this._asyncValueProvider, this._builder, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(_asyncValueProvider).when(
            // TODO ロードしたデータではなく、watchedを渡す
            data: (D loaded) => v(() => _builder(loaded), loaded),
            error: (error, stackTrace) => v(
              () => Text(error.toString()),
              error,
            ),
            loading: () => v(() => const CircularProgressIndicator()),
          );
}
