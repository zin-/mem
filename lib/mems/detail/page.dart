import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/archive_mem_icon_button.dart';
import 'package:mem/mems/detail/body.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/remove_mem_action.dart';
import 'package:mem/mems/detail/transit_act_list_icon_button.dart';
import 'package:mem/mems/detail/transit_chart_icon_button.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/values/colors.dart';

class MemDetailPage extends ConsumerWidget {
  final int? _memId;

  const MemDetailPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _MemDetailPage(
          _memId,
          ref.watch(memIsArchivedProvider(_memId)),
        ),
        {
          "_memId": _memId,
        },
      );
}

class _MemDetailPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final int? _memId;
  final bool _memIsArchived;

  _MemDetailPage(this._memId, this._memIsArchived);

  @override
  Widget build(BuildContext context) => v(
        () => Scaffold(
          appBar: AppBar(
            actions: AppBarActions([
              TransitChartAction(context, _memId),
              TransitActListAction(context, _memId),
              ArchiveMemAction(context, _memId),
              RemoveMemAction(context, _memId),
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
