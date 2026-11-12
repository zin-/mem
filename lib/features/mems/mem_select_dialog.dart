import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/values/dimens.dart';

enum MemSelectMode { single, multiple }

class MemSelectDialog extends StatefulWidget {
  final List<MemEntity> candidates;
  final MemSelectMode mode;
  final Set<int> excludedMemIds;
  final List<int> selectedMemIds;
  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final void Function(List<int> ids) onSubmit;

  const MemSelectDialog({
    super.key,
    required this.candidates,
    required this.mode,
    required this.excludedMemIds,
    required this.selectedMemIds,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onSubmit,
  });

  @override
  State<MemSelectDialog> createState() => _MemSelectDialogState();
}

class _MemSelectDialogState extends State<MemSelectDialog> {
  late String _searchText;
  late List<int> _selectedMemIds;

  @override
  void initState() {
    super.initState();
    _searchText = '';
    _selectedMemIds = List<int>.from(widget.selectedMemIds);
  }

  Iterable<MemEntity> get _visibleCandidates => widget.candidates.where(
        (entity) {
          if (entity.archivedAt != null) return false;
          if (widget.excludedMemIds.contains(entity.id)) return false;
          if (_searchText.isEmpty || entity.name.contains(_searchText)) {
            return true;
          }
          return _selectedMemIds.contains(entity.id);
        },
      );

  List<int> get _submitIds {
    if (widget.mode == MemSelectMode.multiple) return _selectedMemIds;
    if (_selectedMemIds.isEmpty) return const [];
    return [_selectedMemIds.last];
  }

  void _selectMultiple(int id, bool checked) {
    setState(() {
      _selectedMemIds = checked
          ? [..._selectedMemIds, id]
          : _selectedMemIds.where((selectedId) => selectedId != id).toList();
    });
  }

  @override
  Widget build(BuildContext context) => v(
        () {
          final visible = _visibleCandidates.toList();
          final list = ListView.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final mem = visible[index];
              return switch (widget.mode) {
                MemSelectMode.multiple => CheckboxListTile(
                    title: Text(mem.name),
                    value: _selectedMemIds.contains(mem.id),
                    onChanged: (checked) =>
                        _selectMultiple(mem.id, checked == true),
                  ),
                MemSelectMode.single => RadioListTile<int>(
                    title: Text(mem.name),
                    value: mem.id,
                  ),
              };
            },
          );

          return AlertDialog(
            title: Text(widget.title),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.sizeOf(context).height *
                  memSelectDialogContentHeightFactor,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: buildL10n(context).searchMemHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _searchText = value),
                  ),
                  const SizedBox(height: defaultComponentPadding),
                  Expanded(
                    child: widget.mode == MemSelectMode.single
                        ? RadioGroup<int>(
                            groupValue: _selectedMemIds.isEmpty
                                ? null
                                : _selectedMemIds.last,
                            onChanged: (id) {
                              if (id == null) return;
                              setState(() => _selectedMemIds = [id]);
                            },
                            child: list,
                          )
                        : list,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.cancelLabel),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onSubmit(_submitIds);
                  Navigator.of(context).pop();
                },
                child: Text(widget.confirmLabel),
              ),
            ],
          );
        },
        {
          'mode': widget.mode,
          'searchText': _searchText,
          'selectedMemIds': _selectedMemIds,
        },
      );
}
