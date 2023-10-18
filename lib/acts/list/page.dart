import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/list/add_act_fab.dart';
import 'package:mem/logger/log_service.dart';

import 'act_list_view.dart';

class ActListPage extends ConsumerWidget {
  final int _memId;

  const ActListPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () => Scaffold(
          body: ActListView(memId: _memId),
          floatingActionButton: ActFab(_memId),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      );
}
