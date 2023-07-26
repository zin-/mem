import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_list_actions.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';

import '../../core/act.dart';
import 'act_list_item_view.dart';
import 'act_list_page_states.dart';

class ActListView extends ConsumerWidget {
  final MemId _memId;

  const ActListView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView(
        loadActList(_memId),
        (data) {
          final actList = ref.watch(actListProvider(_memId));

          return _ActListViewComponent(actList!.sorted(
            (a, b) => b.id!.compareTo(a.id!),
          ));
        },
      );
}

class _ActListViewComponent extends StatelessWidget {
  final List<Act> actList;

  const _ActListViewComponent(this.actList);

  @override
  Widget build(BuildContext context) => v(
        () {
          return ListView.builder(
            itemCount: actList.length,
            itemBuilder: (context, index) {
              return ActListItemView(context, actList[index]);
            },
          );
        },
        {'actListLength': actList.length, 'actList': actList},
      );
}
