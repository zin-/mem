import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/mems/list/view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/app_bar.dart';
import 'package:mem/mems/transitions.dart';

import 'item/view.dart';

class MemListWidget extends ConsumerWidget {
  final ScrollController _scrollController;

  const MemListWidget(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _render(
          _scrollController,
          (memId) => showMemDetailPage(context, ref, memId),
        ),
      );
}

Widget _render(
  ScrollController scrollController,
  void Function(int memId) onItemTapped,
) =>
    v(
      () => MemListView(
        const MemListAppBar(),
        (memId) => MemListItemView(memId, onItemTapped),
        scrollController: scrollController,
      ),
      {
        'scrollController': scrollController,
        'onItemTapped': onItemTapped,
      },
    );
