import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/actions.dart';
import 'package:mem/mems/list/app_bar.dart';

class MemListBody extends ConsumerWidget {
  final ScrollController _scrollController;

  const MemListBody(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () {
          ref.read(fetchActiveActs);

          return _MemListBodyComponent(_scrollController);
        },
      );
}

class _MemListBodyComponent extends StatelessWidget {
  final ScrollController _scrollController;

  const _MemListBodyComponent(this._scrollController);

  @override
  Widget build(BuildContext context) => MemListView(
        const MemListAppBar(),
        scrollController: _scrollController,
      );
}
