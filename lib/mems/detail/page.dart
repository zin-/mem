import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/body.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/menu.dart';
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
            actions: [
              MemDetailMenu(_memId),
            ],
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
