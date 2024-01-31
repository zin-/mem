import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/archive_mem_action.dart';
import 'package:mem/mems/detail/body.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/remove_mem_action.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/detail/transit_act_list_action.dart';
import 'package:mem/mems/detail/transit_chart_action.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/values/colors.dart';

class MemDetailPage extends ConsumerWidget {
  final int? _memId;

  const MemDetailPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemDetailPage(
          ref.watch(editingMemByMemIdProvider(_memId).select(
            (value) => value is SavedMem ? value.id : null,
          )),
          ref.watch(editingMemByMemIdProvider(_memId).select(
            (value) => value is SavedMem,
          )),
          ref.watch(editingMemByMemIdProvider(_memId).select(
            (value) => value is SavedMem ? value.isArchived : false,
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
            actions: AppBarActions([
              TransitChartAction(context, _memId),
              TransitActListAction(context, _memId),
              ArchiveMemAction(context, _memId, _memIsSaved),
              RemoveMemAction(context, _memId, _memIsSaved),
            ]).build(context),
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
          "_memIsArchived": _memIsArchived,
        },
      );
}
