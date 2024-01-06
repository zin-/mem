import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';

final _asyncValue = FutureProvider.family(
  (ref, future) => v(
    () => future,
    future,
  ),
);

class AsyncValueViewV2 extends ConsumerWidget {
  final Future<dynamic> _future;
  final StateNotifierProvider<ValueStateNotifier, dynamic> _watch;
  final Widget Function(dynamic data, dynamic watched) _builder;

  const AsyncValueViewV2(
    this._future,
    this._watch,
    this._builder, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => ref.watch(_asyncValue(_future)).when(
              data: (data) => v(
                () {
                  Future(() => ref.read(_watch.notifier).updatedBy(data));
                  return _AsyncValueViewV2(
                    _watch,
                    (watched) => _builder(data, watched),
                  );
                },
                {"data": data},
              ),
              error: (error, stackTrace) => w(
                () => Text(error.toString()),
                {"error": error, "stackTrace": stackTrace},
              ),
              loading: () => v(
                () => const Center(child: CircularProgressIndicator()),
              ),
            ),
      );
}

class _AsyncValueViewV2<T> extends ConsumerWidget {
  final ProviderListenable<T> _watch;
  final Widget Function(T watched) _builder;

  const _AsyncValueViewV2(
    this._watch,
    this._builder,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _builder(ref.watch(_watch)),
        {"_watch": _watch},
      );
}

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
