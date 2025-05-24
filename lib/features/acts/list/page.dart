import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/list/add_act_fab.dart';
import 'package:mem/features/logger/log_service.dart';

import 'act_list.dart';

class ActListPage extends ConsumerWidget {
  final _scrollController = ScrollController();

  final int _memId;

  ActListPage(
    this._memId, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () => Scaffold(
          body: ActList(
            _memId,
            _scrollController,
          ),
          floatingActionButton: ActFab(_memId),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      );
}
