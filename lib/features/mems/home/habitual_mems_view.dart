import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/habitual_mems.dart';
import 'package:mem/features/mems/home/home_mems_card.dart';
import 'package:mem/features/mems/home/overdue_mems.dart';
import 'package:mem/features/mems/home/upcoming_mems.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/l10n/l10n.dart';

class HabitualMemsView extends ConsumerWidget {
  const HabitualMemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final shownIds = <int>{
            for (final mem in ref.watch(overdueMemsProvider)) mem.id,
            for (final mem in ref.watch(upcomingMemsProvider)) mem.id,
          };
          final mems = [
            for (final mem
                in ref.watch(habitualMemsProvider).value ?? const <MemEntity>[])
              if (!shownIds.contains(mem.id)) mem,
          ];
          return HomeMemsCard(
            mems,
            title: buildL10n(context).habitualMemsTitle,
          );
        },
      );
}
