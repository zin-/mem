import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/dimens.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/gui/colors.dart';
import 'package:mem/gui/constants.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/body.dart';
import 'package:mem/mems/detail/menu.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/list/page.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/mems_action.dart';

class MemDetailPageV2 extends ConsumerWidget {
  final int? _memId;

  const MemDetailPageV2(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ISSUE #178
    ref.read(
      initialize((memId) => showMemDetailPage(context, ref, memId)),
    );
    final mem = ref.watch(editingMemProvider(_memId));

    return _MemDetailPageComponent(
      _memId,
      mem,
      () => ref.read(saveMem(_memId)),
    );
  }
}

class _MemDetailPageComponent extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  final int? _memId;
  final Mem _mem;
  final Future<MemDetail> Function() _saveMem;

  _MemDetailPageComponent(this._memId, this._mem, this._saveMem);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n().memDetailPageTitle()),
        actions: [
          MemDetailMenu(_memId),
        ],
        backgroundColor: _mem.isArchived() ? archivedColor : primaryColor,
      ),
      body: Padding(
        padding: pagePadding,
        child: Form(
          key: _formKey,
          child: MemDetailBody(_memId),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save_alt),
        onPressed: () => v(
          () async {
            if (_formKey.currentState?.validate() ?? false) {
              _saveMem();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(L10n().saveMemSuccessMessage(
                    _mem.name,
                  )),
                  duration: defaultDismissDuration,
                  dismissDirection: DismissDirection.horizontal,
                ),
              );
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
