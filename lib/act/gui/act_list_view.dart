import 'package:flutter/material.dart';
import 'package:mem/act/gui/act_list_item_view.dart';
import 'package:mem/logger/api.dart';

import 'package:mem/act/domain/act.dart';

class ActListView extends StatelessWidget {
  final List<Act> actList;

  const ActListView(this.actList, {super.key});

  @override
  Widget build(BuildContext context) => v(
        {'actList': actList},
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
