import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/states.dart';

class ActListAppBar extends ConsumerWidget {
  final int? _memId;

  const ActListAppBar(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          return _ActListAppBar(
            _memId == null
                ? null
                : ref
                    .watch(memsProvider)
                    ?.singleWhereOrNull((element) => element.id == _memId)
                    ?.name,
          );
        },
        _memId,
      );
}

// TODO add toggle
//  最初は日毎の合計時間で件数に変更できる
//  state自体はActListの下に定義する
class _ActListAppBar extends StatelessWidget {
  final String? _memName;

  const _ActListAppBar(this._memName);

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: Text(_memName ?? buildL10n(context).actListPageTitle),
          floating: true,
        ),
        _memName,
      );
}
