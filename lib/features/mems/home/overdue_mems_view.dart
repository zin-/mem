import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/home_mems_card.dart';
import 'package:mem/features/mems/home/overdue_mems.dart';
import 'package:mem/values/colors.dart';

class OverdueMemsView extends ConsumerStatefulWidget {
  const OverdueMemsView({super.key});

  @override
  ConsumerState<OverdueMemsView> createState() => _OverdueMemsViewState();
}

class _OverdueMemsViewState extends ConsumerState<OverdueMemsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(overdueMemsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) => v(
        () => HomeMemsCard(
          ref.watch(overdueMemsProvider),
          color: warningSurfaceOn(Theme.of(context).colorScheme.surface),
        ),
      );
}
