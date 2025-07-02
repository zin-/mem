import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';

class MemRelationDialogStateful extends StatefulWidget {
  final int? sourceMemId;

  const MemRelationDialogStateful({super.key, this.sourceMemId});

  @override
  State<MemRelationDialogStateful> createState() =>
      _MemRelationDialogStatefulState();
}

class _MemRelationDialogStatefulState extends State<MemRelationDialogStateful> {
  String searchText = "";
  List<int> selectedIds = [];

  @override
  Widget build(BuildContext context) {
    return MemRelationDialogConsumer(
      searchText: searchText,
      onSearchTextChanged: (searchText) =>
          setState(() => this.searchText = searchText),
      selectedIds: selectedIds,
      onSelectedIdsChanged: (selectedIds) =>
          setState(() => this.selectedIds = selectedIds),
    );
  }
}

class MemRelationDialogConsumer extends ConsumerWidget {
  final int? sourceMemId;
  final String searchText;
  final void Function(String) onSearchTextChanged;
  final List<int> selectedIds;
  final void Function(List<int>) onSelectedIdsChanged;

  const MemRelationDialogConsumer({
    super.key,
    this.sourceMemId,
    required this.searchText,
    required this.onSearchTextChanged,
    required this.selectedIds,
    required this.onSelectedIdsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memEntities = ref
        .watch(memEntitiesProvider.select((v) => v.where((e) =>
            searchText.isEmpty ||
            e.value.name.contains(searchText) ||
            selectedIds.contains(e.id))))
        .toList();

    return MemRelationDialog(
      searchText: searchText,
      onSearchTextChanged: onSearchTextChanged,
      candidates: memEntities,
      selectedIds: selectedIds,
      onSelectedIdsChanged: onSelectedIdsChanged,
      onAddPressed: () {
        // TODO: リレーション追加の実装
        Navigator.of(context).pop();
      },
    );
  }
}

class MemRelationDialog extends StatelessWidget {
  final String searchText;
  final void Function(String) onSearchTextChanged;
  final List<SavedMemEntityV2> candidates;
  final List<int> selectedIds;
  final void Function(List<int>) onSelectedIdsChanged;
  final void Function() onAddPressed;

  const MemRelationDialog({
    super.key,
    required this.searchText,
    required this.onSearchTextChanged,
    required this.candidates,
    required this.selectedIds,
    required this.onSelectedIdsChanged,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Add Relation",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: "memを検索...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: onSearchTextChanged,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final mem = candidates[index];
                  final isSelected = selectedIds.contains(mem.id);

                  return CheckboxListTile(
                    title: Text(mem.value.name),
                    value: isSelected,
                    onChanged: (checked) {
                      if (checked == true) {
                        onSelectedIdsChanged([...selectedIds, mem.id]);
                      } else {
                        onSelectedIdsChanged(
                            selectedIds.where((id) => id != mem.id).toList());
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("キャンセル"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAddPressed,
                  child: const Text("追加"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
