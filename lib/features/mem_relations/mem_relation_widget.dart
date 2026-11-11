import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_select_dialog.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/framework/date_and_time/time_text_form_field.dart';
import 'package:mem/l10n/l10n.dart';

class MemRelationList extends ConsumerWidget {
  final int? sourceMemId;

  const MemRelationList({
    super.key,
    required this.sourceMemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final l10n = buildL10n(context);
          return ref
              .watch(memRelationEntitiesByMemIdProvider(sourceMemId))
              .when(
            data: (entities) {
              final selectedMemIds = entities.map((e) => e.value.targetMemId);
              final selectedMems = ref
                  .watch(memEntitiesProvider.select(
                    (v) => v.where((e) => selectedMemIds.contains(e.id)),
                  ))
                  .map((e) => e.toDomain());

              void onChanged(int targetMemId, int value) => ref
                      .watch(memRelationEntitiesByMemIdProvider(sourceMemId)
                          .notifier)
                      .upsert([
                    MemRelationEntityV1.by(
                      sourceMemId,
                      targetMemId,
                      MemRelationType.prePost,
                      value,
                    )
                  ]);

              return _MemRelationList(
                selectedMems: selectedMems,
                memRelationEntities: entities,
                showDialog: v(
                  () => () => showDialog(
                        context: context,
                        builder: (context) => MemSelectDialog(
                          candidates: ref.read(memEntitiesProvider).toList(),
                          mode: MemSelectMode.multiple,
                          excludedMemIds: sourceMemId == null
                              ? const <int>{}
                              : {sourceMemId!},
                          selectedMemIds:
                              selectedMems.map((e) => e.id!).toList(),
                          title: l10n.addRelationTitle,
                          confirmLabel: l10n.addAction,
                          cancelLabel: l10n.cancelAction,
                          onSubmit: (selectedIds) {
                            for (final selectedId in selectedIds) {
                              onChanged(selectedId, 0);
                            }
                          },
                        ),
                      ),
                ),
                onChanged: onChanged,
              );
            },
            loading: () {
              return const CircularProgressIndicator();
            },
            error: (error, stackTrace) {
              return Text(l10n.loadError);
            },
          );
        },
        {
          "sourceMemId": sourceMemId,
        },
      );
}

const itemHeight = 60.0;
const maxHeight = itemHeight * 3;

class _MemRelationList extends StatelessWidget {
  final Iterable<Mem> selectedMems;
  final Iterable<MemRelationEntityV1> memRelationEntities;
  final void Function() showDialog;
  final void Function(int targetMemId, int value) onChanged;

  const _MemRelationList({
    required this.selectedMems,
    required this.memRelationEntities,
    required this.showDialog,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          return Column(
            children: [
              Text(l10n.relationsTitle),
              SizedBox(
                height: min(selectedMems.length * itemHeight, maxHeight),
                child: ListView.builder(
                  itemCount: selectedMems.length,
                  itemBuilder: (context, index) {
                    final mem = selectedMems.elementAt(index);

                    return _MemRelationItem(
                      mem: mem,
                      value: memRelationEntities
                          .firstWhere((e) => e.value.targetMemId == mem.id)
                          .value
                          .value,
                      onChanged: (value) => onChanged(mem.id!, value ?? 0),
                    );
                  },
                ),
              ),
              TextButton.icon(
                onPressed: showDialog,
                icon: const Icon(Icons.add),
                label: Text(l10n.addRelationTitle),
              ),
            ],
          );
        },
        {
          "selectedMemEntities": selectedMems,
          "memRelationEntities": memRelationEntities,
        },
      );
}

class _MemRelationItem extends StatelessWidget {
  final Mem mem;
  final int? value;
  final void Function(int? value) onChanged;

  const _MemRelationItem({
    required this.mem,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          return ListTile(
            title: Text(mem.name),
            trailing: SizedBox(
              // FIXME 固定にすると画面サイズに依存してしまう
              width: 120,
              child: TimeTextFormField(
                value,
                onChanged,
              ),
            ),
            // trailing: Text(memRelationEntity.value.value.toString()),
          );
        },
        {
          "mem": mem,
          "value": value,
        },
      );
}
