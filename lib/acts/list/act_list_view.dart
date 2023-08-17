import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

import 'item/view.dart';

class ActListView extends ConsumerWidget {
  final int? _memId;

  const ActListView({int? memId, super.key}) : _memId = memId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView(
        loadActList(_memId),
        (data) => _ActListViewComponent(
          ref.watch(actListProvider(_memId)) ?? [],
        ),
      );
}

class _ActListViewComponent extends StatelessWidget {
  final List<Act> actList;

  const _ActListViewComponent(this.actList);

  @override
  Widget build(BuildContext context) => v(
        () => ListView.builder(
          itemCount: actList.length,
          itemBuilder: (context, index) =>
              // TODO 日付ごとのサブヘッダを追加する
              // TODO ヘッダーを追加する
              //  特定のMemの場合ヘッダーにmem.nameを
              //  そうでない場合はどうする？
              // TODO 特定のMemでない場合、actItemごとにMem.nameを表示する
              //  しかない？
              ActListItemView(context, actList[index]),
        ),
        {'actListLength': actList.length, 'actList': actList},
      );
}
