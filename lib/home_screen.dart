import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mem/features/acts/list/act_list.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/widgets/scroll_controllable_widget.dart';
import 'package:mem/framework/view/drawer.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/list/widget.dart';
import 'package:mem/features/mems/list/show_new_mem_fab.dart';
import 'package:mem/values/dimens.dart';
import 'package:mem/values/durations.dart';

class HomeScreen extends StatelessWidget {
  final ScrollController scrollController = ScrollController();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => HomePage(scrollController);
}

class HomePage extends ScrollControllableWidget {
  const HomePage(super.scrollController, {super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with ScrollControllableStateMixin {
  int _showIndex = 0;

  @override
  Widget build(BuildContext context) => v(
        () {
          final isHidden = scrollDirection == ScrollDirection.reverse;

          final bodies = [
            MemListWidget(widget.scrollController),
            ActList(
              null,
              widget.scrollController,
            ),
          ];
          final floatingActionButtons = [
            ShowNewMemFab(widget.scrollController),
            null,
          ];

          final l10n = buildL10n(context);

          return Scaffold(
            drawer: ApplicationDrawer(),
            body: SafeArea(child: bodies[_showIndex]),
            floatingActionButton: floatingActionButtons[_showIndex],
            bottomNavigationBar: AnimatedContainer(
              height: isHidden ? zeroHeight : defaultNavigationBarHeight,
              duration: defaultTransitionDuration,
              child: AnimatedOpacity(
                opacity: isHidden ? 0.0 : 1.0,
                duration: defaultTransitionDuration,
                child: NavigationBar(
                  selectedIndex: _showIndex,
                  onDestinationSelected: (selectedIndex) => v(
                    () => setState(
                      () => _showIndex = selectedIndex,
                    ),
                    {"selectedIndex": selectedIndex},
                  ),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.list),
                      label: l10n.memListDestinationLabel,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.playlist_play),
                      label: l10n.actListDestinationLabel,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        {
          "_showIndex": _showIndex,
          "scrollDirection": scrollDirection,
        },
      );
}
