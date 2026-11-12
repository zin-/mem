import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/home_mems_card.dart';
import 'package:mem/features/mems/home/upcoming_mems.dart';

class UpcomingMemsView extends ConsumerWidget {
  const UpcomingMemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => HomeMemsCard(ref.watch(upcomingMemsProvider)),
      );
}
