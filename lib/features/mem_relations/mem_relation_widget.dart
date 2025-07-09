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

              return _MemRelationList(
                selectedMemEntities: selectedMemEntities,
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
  final void Function() showDialog;

  const _MemRelationList({
    required this.selectedMemEntities,
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
                    return _MemRelationItem(
                      memEntity: memEntity,
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
        },
      );
}

class _MemRelationItem extends StatelessWidget {
  final MemEntityV2 memEntity;

  const _MemRelationItem({
    required this.memEntity,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          return ListTile(
            title: Text(memEntity.value.name),
          );
        },
        {
          "memEntity": memEntity,
        },
      );
}
