import 'package:material_ui/material_ui.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/values/dimens.dart';

class HomeMemsCard extends StatelessWidget {
  final List<MemEntity> _mems;
  final Color? _color;

  const HomeMemsCard(
    this._mems, {
    super.key,
    Color? color,
  }) : _color = color;

  @override
  Widget build(BuildContext context) {
    if (_mems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: cardMargin,
      color: _color,
      clipBehavior: Clip.antiAlias,
      semanticContainer: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
