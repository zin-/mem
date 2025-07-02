import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mem_items/mem_items_view.dart';
import 'package:mem/features/mem_notifications/mem_notifications_view.dart';
import 'package:mem/features/mem_relations/mem_relation_widget.dart';
import 'package:mem/framework/date_and_time/created_and_updated_at_texts.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/targets/target_view.dart';
import 'package:mem/features/mems/mem_done_checkbox.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mems/mem_period.dart';
import 'package:mem/values/dimens.dart';

import 'states.dart';

class MemDetailBody extends ConsumerWidget {
  final int? _memId;

  const MemDetailBody(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final editingMem = ref.watch(editingMemByMemIdProvider(_memId));

          return _MemDetailBodyComponent(
            _memId,
            editingMem,
            (value) => ref
                .read(editingMemByMemIdProvider(_memId).notifier)
                .updatedBy(
                  editingMem.updatedWith(
                    (mem) =>
                        value == true ? mem.done(DateTime.now()) : mem.undone(),
                  ),
                ),
          );
        },
        _memId.toString(),
      );
}

class _MemDetailBodyComponent extends StatelessWidget {
  final int? _memId;
  final MemEntityV2 _mem;
  final Function(bool? memDone) _onMemDoneChanged;

  const _MemDetailBodyComponent(
    this._memId,
    this._mem,
    this._onMemDoneChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: pageTopPadding,
                  child: Column(
                    children: [
                      MemNameTextFormField(_memId),
                      MemDoneCheckbox(
                        _mem,
                        _onMemDoneChanged,
                      ),
                      MemPeriodTextFormFields(_memId),
                      MemNotificationsView(_memId),
                      TargetText(_memId),
                      MemItemsFormFields(_memId),
                      MemRelationListConsumer(sourceMemId: _memId),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: pageBottomPadding,
              child: CreatedAndUpdatedAtTexts(_mem),
            ),
          ],
        ),
        {
          '_memId': _memId,
          '_mem': _mem,
        },
      );
}
