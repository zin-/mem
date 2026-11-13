import 'package:material_ui/material_ui.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/values/dimens.dart';

class HomeMemsCard extends StatelessWidget {
  final List<MemEntity> _mems;
  final Color? _color;
  final String? _title;

  const HomeMemsCard(
    this._mems, {
    super.key,
    Color? color,
    String? title,
  })  : _color = color,
        _title = title;

  @override
  Widget build(BuildContext context) {
    if (_mems.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = _title;
    final theme = Theme.of(context);

    return Card(
      margin: cardMargin,
      color: _color,
      clipBehavior: Clip.antiAlias,
      semanticContainer: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: defaultPadding,
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final mem in _mems)
            MemListItemView(
              mem.toDomain(),
              key: ValueKey(mem.id),
            ),
        ],
      ),
    );
  }
}
