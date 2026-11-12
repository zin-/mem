import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/home_mems_card.dart';
import 'package:mem/features/mems/home/overdue_mems.dart';
import 'package:mem/values/colors.dart';

class OverdueMemsView extends ConsumerWidget {
  const OverdueMemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => HomeMemsCard(
          ref.watch(overdueMemsProvider),
          color: warningSurfaceOn(Theme.of(context).colorScheme.surface),
        ),
      );
}
