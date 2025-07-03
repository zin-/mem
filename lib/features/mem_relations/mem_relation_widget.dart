import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Widget build(BuildContext context) {
    return _MemRelationListConsumer(
      sourceMemId: widget.sourceMemId,
      selectedMemIds: selectedMemIds,
      onSelectedMemIdsChanged: (selectedMemIds) {
        setState(() {
          this.selectedMemIds = selectedMemIds;
        });
      },
    );
  }
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
  Widget build(BuildContext context, WidgetRef ref) {
    final memRelationEntities =
        ref.watch(memRelationEntitiesByMemIdProvider(sourceMemId));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => onSelectedMemIdsChanged(
        memRelationEntities.map((e) => e.value.targetMemId),
      ),
    );

    final memEntities = ref.watch(memEntitiesProvider.select(
      (v) => v.where((e) =>
          memRelationEntities.map((e) => e.value.targetMemId).contains(e.id)),
    ));

    return _MemRelationList(
      memRelationEntities: memRelationEntities,
      memEntities: memEntities,
      showDialog: () {
        showDialog(
          context: context,
          builder: (context) => MemRelationDialogStateful(
            sourceMemId: sourceMemId,
            selectedIds:
                memRelationEntities.map((e) => e.value.targetMemId).toList(),
            onSubmit: (selectedIds) {
              onSelectedMemIdsChanged(selectedIds);
            },
          ),
        );
      },
    );
  }
}

const itemHeight = 60.0;
const maxHeight = itemHeight * 3;

class _MemRelationList extends StatelessWidget {
  final Iterable<MemRelationEntity> memRelationEntities;
  final Iterable<SavedMemEntityV2> memEntities;
  final void Function() showDialog;

  const _MemRelationList({
    required this.memRelationEntities,
    required this.memEntities,
    required this.showDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Relations"),
        SizedBox(
          height: min(memRelationEntities.length * itemHeight, maxHeight),
          child: ListView.builder(
            itemCount: memRelationEntities.length,
            itemBuilder: (context, index) {
              final memRelationEntity = memRelationEntities.elementAt(index);
              return _MemRelationItem(
                memRelationEntity: memRelationEntity,
                memEntity: memEntities.singleWhere(
                    (e) => e.id == memRelationEntity.value.targetMemId),
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
  }
}

class _MemRelationItem extends StatelessWidget {
  final MemRelationEntity memRelationEntity;
  final MemEntityV2 memEntity;

  const _MemRelationItem({
    required this.memRelationEntity,
    required this.memEntity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(memEntity.value.name),
        Text(memRelationEntity.value.type.toString()),
      ],
    );
  }
}
