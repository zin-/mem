import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/list/act_list.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/scroll_controllable_widget.dart';
import 'package:mem/drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/body.dart';
import 'package:mem/mems/list/show_new_mem_fab.dart';
import 'package:mem/values/dimens.dart';
import 'package:mem/values/durations.dart';

class MemApplication extends StatelessWidget {
  final ScrollController scrollController = ScrollController();

  final Widget? home;
  final String? languageCode;

  MemApplication(
    this.languageCode, {
    this.home,
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return ProviderScope(
            child: MaterialApp(
              onGenerateTitle: (context) => l10n.appTitle,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: languageCode == null ? null : Locale(languageCode!),
              theme: ThemeData.light(useMaterial3: true),
              home: home ?? _HomePage(scrollController),
            ),
          );
        },
      );
}

class _HomePage extends ScrollControllableWidget {
  const _HomePage(super.scrollController) : super();

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage>
    with ScrollControllableStateMixin {
  int _showIndex = 0;

  @override
  Widget build(BuildContext context) => v(
        () {
          final isHidden = scrollDirection == ScrollDirection.reverse;

          final bodies = [
            MemListBody(widget.scrollController),
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
            drawer: ApplicationDrawer(l10n),
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
