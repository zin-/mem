import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/gui/async_value_view.dart';
import 'package:mem/logger/api.dart';

import '../domain/act.dart';

import 'act_list_page_actions.dart';
import 'act_list_page_states.dart';
import 'act_list_view.dart';

class ActListPage extends ConsumerWidget {
  const ActListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => t(
        {},
        () {
          return Scaffold(
            body: buildBody(ref, (List<Act> actList) => ActListView(actList)),
          );
        },
      );

  Widget buildBody(
    WidgetRef ref,
    Widget Function(List<Act> actList) buildFunction,
  ) =>
      v(
        {},
        () {
          final actList = ref.watch(actListProvider);
          if (actList == null) {
            return AsyncValueView(
              ref.watch(fetchActList),
              (List<Act> data) => buildFunction(data),
            );
          } else {
            return buildFunction(actList);
          }
        },
      );
}
