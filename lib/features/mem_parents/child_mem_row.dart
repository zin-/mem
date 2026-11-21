import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/l10n/l10n.dart';

class ChildMemRow extends StatelessWidget {
  final Mem _child;
  final VoidCallback _onDisconnect;

  const ChildMemRow({
    required Mem child,
    required VoidCallback onDisconnect,
    super.key,
  })  : _child = child,
        _onDisconnect = onDisconnect;

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          return MemListItemView(
            _child,
            showPause: false,
            beforeLeading: const Icon(Icons.subdirectory_arrow_right),
            afterTrailing: IconButton(
              onPressed: _onDisconnect,
              tooltip: l10n.disconnectParentAction,
              icon: const Icon(Icons.close),
            ),
            contentPadding: EdgeInsets.zero,
          );
        },
        _child,
      );
}
