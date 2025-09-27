import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/app_bar_actions_builder.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/app_bar/archive_mem_action.dart';
import 'package:mem/features/mems/detail/body.dart';
import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/features/mems/detail/app_bar/remove_mem_action.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/detail/app_bar/transit_act_list_action.dart';
import 'package:mem/features/mems/detail/app_bar/transit_chart_action.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/values/colors.dart';

class MemDetailPage extends ConsumerWidget {
  final int? _memId;

  const MemDetailPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemDetailPage(
          ref.watch(editingMemByMemIdProvider(_memId).select(
            (value) => value is SavedMemEntity ? value.id : null,
          )),
          ref.watch(editingMemByMemIdProvider(_memId).select(
            (value) => value is SavedMemEntity,
          )),
          ref.watch(editingMemByMemIdProvider(_memId).select(
            (value) => value is SavedMemEntity ? value.isArchived : false,
          )),
        ),
        {
          "_memId": _memId,
        },
      );
}

class _MemDetailPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final int? _memId;
  final bool _memIsSaved;
  final bool _memIsArchived;

  _MemDetailPage(this._memId, this._memIsSaved, this._memIsArchived);

  @override
  Widget build(BuildContext context) => v(
        () => Scaffold(
          appBar: AppBar(
            actions: _memIsSaved
                ? AppBarActionsBuilder([
                    TransitChartAction(context, _memId!),
                    TransitActListAction(context, _memId),
                    ArchiveMemAction(_memId),
                    RemoveMemAction(_memId),
                  ]).build(context)
                : null,
            backgroundColor: _memIsArchived ? secondaryGreyColor : null,
          ),
          body: Form(
            key: _formKey,
            child: MemDetailBody(_memId),
          ),
          floatingActionButton: MemDetailFab(_formKey, _memId),
        ),
        {
          "_memId": _memId,
          "_memIsSaved": _memIsSaved,
          "_memIsArchived": _memIsArchived,
        },
      );
}
