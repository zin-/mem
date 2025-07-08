import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_search_dialog.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';

class MemRelationListStateful extends StatefulWidget {
  final int? sourceMemId;

  const MemRelationListStateful({
    super.key,
    required this.sourceMemId,
  });

  @override
  State<MemRelationListStateful> createState() =>
      _MemRelationListStatefulState();
}

class _MemRelationListStatefulState extends State<MemRelationListStateful> {
  // 未保存も含む選択されているMemのid
  Iterable<int> selectedMemIds = [];

  @override
  Widget build(BuildContext context) => v(
        () {
          return _MemRelationListConsumer(
            sourceMemId: widget.sourceMemId,
            selectedMemIds: selectedMemIds,
            onSelectedMemIdsChanged: (selectedMemIds) => v(
              () {
                if (SetEquality().equals(
                    this.selectedMemIds.toSet(), selectedMemIds.toSet())) {
                  return;
                }
                setState(() => this.selectedMemIds = selectedMemIds);
              },
              {
                "this.selectedMemIds": this.selectedMemIds,
                "selectedMemIds": selectedMemIds,
              },
            ),
          );
        },
        {
          "widget.sourceMemId": widget.sourceMemId,
          "selectedMemIds": selectedMemIds,
        },
      );
}

class _MemRelationListConsumer extends ConsumerWidget {
  final int? sourceMemId;
  final Iterable<int> selectedMemIds;
  final void Function(Iterable<int>) onSelectedMemIdsChanged;

  const _MemRelationListConsumer({
    required this.sourceMemId,
    required this.selectedMemIds,
    required this.onSelectedMemIdsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          if (sourceMemId != null) {
            ref
                .watch(memRelationEntitiesByMemIdProvider(sourceMemId).notifier)
                .fetch(sourceMemId!);
          }
          final memRelationEntities =
              ref.watch(memRelationEntitiesByMemIdProvider(sourceMemId));
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => onSelectedMemIdsChanged(
              [
                ...selectedMemIds,
                ...memRelationEntities.map((e) => e.value.targetMemId)
              ],
            ),
          );

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
                        onSelectedMemIdsChanged(selectedIds);
                        ref
                            .read(
                                memRelationEntitiesByMemIdProvider(sourceMemId)
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
        {
          "sourceMemId": sourceMemId,
          "selectedMemIds": selectedMemIds,
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
