import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_search_dialog.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';

class MemRelationListConsumer extends ConsumerWidget {
  final int? sourceMemId;

  const MemRelationListConsumer({super.key, this.sourceMemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memRelationEntities =
        ref.watch(memRelationEntitiesByMemIdProvider(sourceMemId));
    final memEntities = ref.watch(memEntitiesProvider.select((v) => v.where(
        (e) => memRelationEntities
            .map((e) => e.value.targetMemId)
            .contains(e.id))));

    return MemRelationListStateful(
      memRelationEntities: memRelationEntities,
      memEntities: memEntities,
      showDialog: (onSubmit) {
        showDialog(
          context: context,
          builder: (context) => MemRelationDialogStateful(
            sourceMemId: sourceMemId,
            selectedIds:
                memRelationEntities.map((e) => e.value.targetMemId).toList(),
            onSubmit: onSubmit,
          ),
        );
      },
    );
  }
}

class MemRelationListStateful extends StatefulWidget {
  final Iterable<MemRelationEntity> memRelationEntities;
  final Iterable<SavedMemEntityV2> memEntities;
  final void Function(Function(List<int>) onSubmit) showDialog;

  const MemRelationListStateful({
    super.key,
    required this.memRelationEntities,
    required this.memEntities,
    required this.showDialog,
  });

  @override
  State<MemRelationListStateful> createState() =>
      _MemRelationListStatefulState();
}

class _MemRelationListStatefulState extends State<MemRelationListStateful> {
  Iterable<int> targetMemIds = [];

  @override
  Widget build(BuildContext context) {
    return _MemRelationList(
      memRelationEntities: widget.memRelationEntities,
      memEntities: widget.memEntities,
      showDialog: () {
        widget.showDialog(
          (selectedIds) {
            setState(() {
              targetMemIds = selectedIds;
            });
          },
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
              return MemRelationItem(
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

class MemRelationItem extends StatelessWidget {
  final MemRelationEntity memRelationEntity;
  final MemEntityV2 memEntity;

  const MemRelationItem({
    super.key,
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
