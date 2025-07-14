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
              final memRelationEntities = ref.watch(
                  memRelationEntitiesProvider.select((v) =>
                      v.where((e) => e.value.sourceMemId == sourceMemId)));

              return _MemRelationList(
                selectedMemEntities: selectedMemEntities,
                memRelationEntities: memRelationEntities,
                showDialog: v(
                  () => () => showDialog(
                        context: context,
                        builder: (context) => MemRelationDialogStateful(
                          sourceMemId: sourceMemId,
                          selectedMemIds:
                              selectedMemEntities.map((e) => e.id).toList(),
                          onSubmit: (selectedIds) {
                            ref
                                .watch(memRelationEntitiesByMemIdProvider(
                                        sourceMemId)
                                    .notifier)
                                .upsert(selectedIds
                                    .map((selectedId) => MemRelationEntity.by(
                                          sourceMemId,
                                          selectedId,
                                          MemRelationType.prePost,
                                          // TODO
                                          Random().nextInt(100),
                                        )));
                          },
                        ),
                      ),
                ),
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
  final Iterable<SavedMemRelationEntity> memRelationEntities;
  final void Function() showDialog;

  const _MemRelationList({
    required this.selectedMemEntities,
    required this.memRelationEntities,
    required this.showDialog,
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
                    final memRelationEntity = memRelationEntities.firstWhere(
                      (e) => e.value.targetMemId == memEntity.id,
                    );

                    return _MemRelationItem(
                      memEntity: memEntity,
                      memRelationEntity: memRelationEntity,
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
  final MemEntityV2 memEntity;
  final SavedMemRelationEntity memRelationEntity;

  const _MemRelationItem({
    required this.memEntity,
    required this.memRelationEntity,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          return ListTile(
            title: Text(memEntity.value.name),
            subtitle: Text(memRelationEntity.value.type.name),
            trailing: Text(memRelationEntity.value.value.toString()),
          );
        },
        {
          "memEntity": memEntity,
          "memRelationEntity": memRelationEntity,
        },
      );
}
