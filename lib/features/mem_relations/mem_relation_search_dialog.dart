import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';

class MemRelationDialogStateful extends StatefulWidget {
  final int? sourceMemId;
  final List<int> selectedMemIds;
  final void Function(List<int>) onSubmit;

  const MemRelationDialogStateful({
    super.key,
    required this.sourceMemId,
    required this.selectedMemIds,
    required this.onSubmit,
  });

  @override
  State<MemRelationDialogStateful> createState() =>
      _MemRelationDialogStatefulState();
}

class _MemRelationDialogStatefulState extends State<MemRelationDialogStateful> {
  late String searchText;
  late List<int> selectedMemIds;

  @override
  void initState() {
    super.initState();
    searchText = "";
    selectedMemIds = List.from(widget.selectedMemIds);
  }

  @override
  Widget build(BuildContext context) => v(
        () {
          return MemRelationDialogConsumer(
            sourceMemId: widget.sourceMemId,
            searchText: searchText,
            onSearchTextChanged: (searchText) =>
                setState(() => this.searchText = searchText),
            selectedMemIds: selectedMemIds,
            onSelectedIdsChanged: (selectedMemIds) =>
                setState(() => this.selectedMemIds = selectedMemIds),
            onSubmit: widget.onSubmit,
          );
        },
        {
          "widget.sourceMemId": widget.sourceMemId,
          "selectedMemIds": selectedMemIds,
        },
      );
}

class MemRelationDialogConsumer extends ConsumerWidget {
  final int? sourceMemId;
  final String searchText;
  final void Function(String) onSearchTextChanged;
  final List<int> selectedMemIds;
  final void Function(List<int>) onSelectedIdsChanged;
  final void Function(List<int>) onSubmit;

  const MemRelationDialogConsumer({
    super.key,
    this.sourceMemId,
    required this.searchText,
    required this.onSearchTextChanged,
    required this.selectedMemIds,
    required this.onSelectedIdsChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final candidates = ref
              .watch(memEntitiesProvider.select((v) => v
                  .where((e) =>
                      searchText.isEmpty ||
                      e.value.name.contains(searchText) ||
                      selectedMemIds.contains(e.id))
                  .where((e) => e.id != sourceMemId)))
              .toList();

          return MemRelationDialog(
            searchText: searchText,
            onSearchTextChanged: onSearchTextChanged,
            candidates: candidates,
            selectedMemIds: selectedMemIds,
            onSelectedIdsChanged: onSelectedIdsChanged,
            onAddPressed: () {
              onSubmit(selectedMemIds);
            },
          );
        },
        {
          "sourceMemId": sourceMemId,
          "searchText": searchText,
          "selectedMemIds": selectedMemIds,
        },
      );
}

const searchMemRelationDialogSearchFieldKey =
    Key("search_mem_relation_dialog_search_field");

class MemRelationDialog extends StatelessWidget {
  final String searchText;
  final void Function(String) onSearchTextChanged;
  final List<SavedMemEntityV1> candidates;
  final List<int> selectedMemIds;
  final void Function(List<int>) onSelectedIdsChanged;
  final void Function() onAddPressed;

  const MemRelationDialog({
    super.key,
    required this.searchText,
    required this.onSearchTextChanged,
    required this.candidates,
    required this.selectedMemIds,
    required this.onSelectedIdsChanged,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          return Dialog(
            child: Container(
              width: 400,
              height: 500,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("Add Relation",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    key: searchMemRelationDialogSearchFieldKey,
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
                        final isSelected = selectedMemIds.contains(mem.id);

                        return CheckboxListTile(
                          title: Text(mem.value.name),
                          value: isSelected,
                          onChanged: (checked) {
                            if (checked == true) {
                              onSelectedIdsChanged([...selectedMemIds, mem.id]);
                            } else {
                              onSelectedIdsChanged(selectedMemIds
                                  .where((id) => id != mem.id)
                                  .toList());
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
                        onPressed: () {
                          onAddPressed();
                          Navigator.of(context).pop();
                        },
                        child: const Text("追加"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        {
          "searchText": searchText,
          "candidates": candidates,
          "selectedMemIds": selectedMemIds,
        },
      );
}
