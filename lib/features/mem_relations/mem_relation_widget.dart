import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_search_dialog.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/framework/date_and_time/time_text_form_field.dart';

class MemRelationList extends ConsumerWidget {
  final int? sourceMemId;

  const MemRelationList({
    super.key,
    required this.sourceMemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          return ref
              .watch(memRelationEntitiesByMemIdProvider(sourceMemId))
              .when(
            data: (entities) {
              final selectedMemIds = entities.map((e) => e.value.targetMemId);
              final selectedMemEntities = ref.watch(memEntitiesProvider.select(
                (v) => v.where((e) => selectedMemIds.contains(e.id)),
              ));

              void onChanged(int targetMemId, int value) => ref
                      .watch(memRelationEntitiesByMemIdProvider(sourceMemId)
                          .notifier)
                      .upsert([
                    MemRelationEntity.by(
                      sourceMemId,
                      targetMemId,
                      MemRelationType.prePost,
                      value,
                    )
                  ]);

              return _MemRelationList(
                selectedMemEntities: selectedMemEntities,
                memRelationEntities: entities,
                showDialog: v(
                  () => () => showDialog(
                        context: context,
                        builder: (context) => MemRelationDialogStateful(
                          sourceMemId: sourceMemId,
                          selectedMemIds:
                              selectedMemEntities.map((e) => e.id).toList(),
                          onSubmit: (selectedIds) {
                            for (var selectedId in selectedIds) {
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
              return const Text("Error");
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
  final Iterable<SavedMemEntityV2> selectedMemEntities;
  final Iterable<MemRelationEntity> memRelationEntities;
  final void Function() showDialog;
  final void Function(int targetMemId, int value) onChanged;

  const _MemRelationList({
    required this.selectedMemEntities,
    required this.memRelationEntities,
    required this.showDialog,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          return Column(
            children: [
              Text("Relations"),
              SizedBox(
                height: min(selectedMemEntities.length * itemHeight, maxHeight),
                child: ListView.builder(
                  itemCount: selectedMemEntities.length,
                  itemBuilder: (context, index) {
                    final memEntity = selectedMemEntities.elementAt(index);

                    return _MemRelationItem(
                      memEntity: memEntity,
                      value: memRelationEntities
                          .firstWhere(
                              (e) => e.value.targetMemId == memEntity.id)
                          .value
                          .value,
                      onChanged: (value) => onChanged(memEntity.id, value ?? 0),
                    );
                  },
                ),
              ),
              TextButton.icon(
                onPressed: showDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add Relation"),
              ),
            ],
          );
        },
        {
          "selectedMemEntities": selectedMemEntities,
          "memRelationEntities": memRelationEntities,
        },
      );
}

class _MemRelationItem extends StatelessWidget {
  final MemEntity memEntity;
  final int? value;
  final void Function(int? value) onChanged;

  const _MemRelationItem({
    required this.memEntity,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          return ListTile(
            title: Text(memEntity.value.name),
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
          "memEntity": memEntity,
          "value": value,
        },
      );
}
