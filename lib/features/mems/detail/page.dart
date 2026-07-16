import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/app_bar_actions_builder.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/app_bar/archive_mem_action.dart';
import 'package:mem/features/mems/detail/body.dart';
import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/features/mems/detail/app_bar/remove_mem_action.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/detail/app_bar/transit_act_list_action.dart';
import 'package:mem/features/mems/detail/app_bar/transit_chart_action.dart';
import 'package:mem/values/colors.dart';

class MemDetailPage extends ConsumerWidget {
  final int? _memId;

  const MemDetailPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemDetailPage(
          ref.watch(editingMemByMemIdProvider(_memId).select(
            (mem) => mem.value.id,
          )),
          ref.watch(editingMemByMemIdProvider(_memId).select(
            (mem) => mem.isSaved,
          )),
          ref.watch(memByMemIdProvider(_memId).select(
            (mem) => mem?.isArchived ?? false,
          )),
        ),
        {
          "_memId": _memId,
        },
      );
}

class _MemDetailPage extends StatefulWidget {
  final int? _memId;
  final bool _memIsSaved;
  final bool _memIsArchived;

  const _MemDetailPage(this._memId, this._memIsSaved, this._memIsArchived);

  @override
  State<_MemDetailPage> createState() => _MemDetailPageState();
}

class _MemDetailPageState extends State<_MemDetailPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => v(
        () => Scaffold(
          appBar: AppBar(
            actions: widget._memIsSaved
                ? AppBarActionsBuilder([
                    TransitChartAction(context, widget._memId!),
                    TransitActListAction(context, widget._memId!),
                    ArchiveMemAction(widget._memId!),
                    RemoveMemAction(widget._memId!),
                  ]).build(context)
                : null,
            backgroundColor: widget._memIsArchived ? secondaryGreyColor : null,
          ),
          body: Form(
            key: _formKey,
            child: MemDetailBody(widget._memId),
          ),
          floatingActionButton: MemDetailFab(_formKey, widget._memId),
        ),
        {
          "_memId": widget._memId,
          "_memIsSaved": widget._memIsSaved,
          "_memIsArchived": widget._memIsArchived,
        },
      );
}
