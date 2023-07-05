import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/body.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/menu.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/list/page.dart';
import 'package:mem/mems/mems_action.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/dimens.dart';

class MemDetailPage extends ConsumerWidget {
  final int? _memId;

  const MemDetailPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          // ISSUE #178
          ref.read(
            initialize((memId) => showMemDetailPage(context, ref, memId)),
          );
          final memIsArchived = ref.watch(memIsArchivedProvider(_memId));

          return _MemDetailPageComponent(
            _memId,
            memIsArchived,
          );
        },
        _memId.toString(),
      );
}

class _MemDetailPageComponent extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  final int? _memId;
  final bool _memIsArchived;

  _MemDetailPageComponent(this._memId, this._memIsArchived);

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.memDetailPageTitle),
              actions: [
                MemDetailMenu(_memId),
              ],
              backgroundColor: _memIsArchived ? archivedColor : primaryColor,
            ),
            body: Padding(
              padding: pagePadding,
              child: Form(
                key: _formKey,
                child: MemDetailBody(_memId),
              ),
            ),
            floatingActionButton: MemDetailFab(_formKey, _memId),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
        {_memId.toString(), _memIsArchived},
      );
}
