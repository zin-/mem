import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/i/api.dart';

import '../core/act.dart';

import 'act_list_item_view.dart';
import 'act_list_page_states.dart';

class ActListView extends ConsumerWidget {
  const ActListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        {},
        () {
          final actList = ref.watch(actListProvider);

          if (actList == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return _ActListViewComponent(actList);
          }
        },
      );
}

class _ActListViewComponent extends StatelessWidget {
  final List<Act> actList;

  const _ActListViewComponent(this.actList);

  @override
  Widget build(BuildContext context) => v(
        {'actListLength': actList.length, 'actList': actList},
        () {
          return ListView.builder(
            itemCount: actList.length,
            itemBuilder: (context, index) {
              return ActListItemView(actList[index]);
            },
          );
        },
      );
}
