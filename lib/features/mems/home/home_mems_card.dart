import 'package:material_ui/material_ui.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/values/dimens.dart';

class HomeMemsCard extends StatelessWidget {
  final List<MemEntity> _mems;
  final Color? _color;
  final IconData? _icon;
  final Widget Function(MemEntity mem)? _subtitle;

  const HomeMemsCard(
    this._mems, {
    super.key,
    Color? color,
    IconData? icon,
    Widget Function(MemEntity mem)? subtitle,
  })  : _color = color,
        _icon = icon,
        _subtitle = subtitle;

  @override
  Widget build(BuildContext context) {
    if (_mems.isEmpty) {
      return const SizedBox.shrink();
    }

    final icon = _icon;
    final subtitle = _subtitle;
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
          if (icon != null)
            Padding(
              padding: defaultPadding,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final mem in _mems)
            MemListItemView(
              mem.toDomain(),
              key: ValueKey(mem.id),
              subtitle: subtitle?.call(mem),
            ),
        ],
      ),
    );
  }
}
