import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/api.dart';

import 'act_list_page_states.dart';
import 'act_list_view.dart';

class ActListPage extends ConsumerWidget {
  const ActListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => t(
        {},
        () {
          final actList = ref.watch(actListProvider)!;

          return Scaffold(
            body: ActListView(actList),
          );
        },
      );
}
