import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/app_bar.dart';
import 'package:mem/mems/transitions.dart';

import 'item/view.dart';

class MemListBody extends ConsumerWidget {
  final ScrollController _scrollController;

  const MemListBody(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          return _MemListBodyComponent(
            _scrollController,
            (memId) => showMemDetailPage(context, ref, memId),
          );
        },
      );
}

class _MemListBodyComponent extends StatelessWidget {
  final ScrollController _scrollController;
  final void Function(int memId) _onItemTapped;

  const _MemListBodyComponent(this._scrollController, this._onItemTapped);

  @override
  Widget build(BuildContext context) => MemListView(
        const MemListAppBar(),
        (memId) => MemListItemView(memId, _onItemTapped),
        scrollController: _scrollController,
      );
}
