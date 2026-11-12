import 'package:material_ui/material_ui.dart';

const secondaryGreyColor = Colors.grey;
const warningColor = Colors.red;

const _warningSurfaceAlpha = 0.24;

Color warningSurfaceOn(Color surface) => Color.alphaBlend(
      warningColor.withValues(alpha: _warningSurfaceAlpha),
      surface,
    );
