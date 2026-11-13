import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/habitual_mems_view.dart';
import 'package:mem/features/mems/home/overdue_mems_view.dart';
import 'package:mem/features/mems/home/upcoming_mems_view.dart';
import 'package:mem/values/dimens.dart';

class HomeView extends StatelessWidget {
  final ScrollController _scrollController;

  const HomeView(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () => ListView(
          controller: _scrollController,
          padding: cardListPadding,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            OverdueMemsView(),
            UpcomingMemsView(),
            HabitualMemsView(),
          ],
        ),
        {
          '_scrollController': _scrollController,
        },
      );
}
