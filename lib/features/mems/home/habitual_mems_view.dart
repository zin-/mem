import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/habitual_mems.dart';
import 'package:mem/features/mems/home/habitual_rank_label.dart';
import 'package:mem/features/mems/home/home_mems_card.dart';
import 'package:mem/features/mems/home/overdue_mems.dart';
import 'package:mem/features/mems/home/upcoming_mems.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';

class HabitualMemsView extends ConsumerWidget {
  const HabitualMemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final shownIds = <int>{
            for (final mem in ref.watch(overdueMemsProvider).value ?? const [])
              mem.id,
            for (final mem in ref.watch(upcomingMemsProvider)) mem.id,
          };
          final count = ref.watch(preferenceProvider(habitualMemsCountKey));
          final habitualMems = [
            for (final habitual in ref.watch(habitualMemsProvider).value ??
                const <HabitualMem>[])
              if (!shownIds.contains(habitual.mem.id)) habitual,
          ].take(count).toList();
          final rankByMemId = {
            for (final habitual in habitualMems) habitual.mem.id: habitual.rank,
          };
          return HomeMemsCard(
            [for (final habitual in habitualMems) habitual.mem],
            icon: Icons.schedule,
            subtitle: (mem) => HabitualRankLabel(rankByMemId[mem.id]!),
          );
        },
      );
}
