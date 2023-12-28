import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/list/act_list.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/body.dart';
import 'package:mem/mems/list/show_new_mem_fab.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/values/dimens.dart';
import 'package:mem/values/durations.dart';

class MemApplication extends StatelessWidget {
  final Widget? home;
  final String? languageCode;

  const MemApplication(this.languageCode, {this.home, super.key});

  @override
  Widget build(BuildContext context) => i(
        () {
          NotificationClient(context);
          final l10n = buildL10n(context);

          return ProviderScope(
            child: MaterialApp(
              onGenerateTitle: (context) => l10n.appTitle,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: languageCode == null ? null : Locale(languageCode!),
              theme: ThemeData.light(useMaterial3: true),
              home: home ?? _HomePage(),
            ),
          );
        },
      );
}

class _HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  static final _scrollController = ScrollController();

  final _bodies = [
    MemListBody(_scrollController),
    ActList(
      null,
      _scrollController,
    ),
  ];
  final _floatingActionButtons = [
    ShowNewMemFab(_scrollController),
    null,
  ];

  int _showIndex = 0;
  bool _bottomAppBarIsHidden = false;

  @override
  void initState() => v(
        () {
          super.initState();
          _scrollController.addListener(_toggleShowOnScroll);
        },
      );

  @override
  void dispose() => v(
        () {
          _scrollController.removeListener(_toggleShowOnScroll);
          super.dispose();
        },
      );

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return Scaffold(
            body: SafeArea(child: _bodies[_showIndex]),
            floatingActionButton: _floatingActionButtons[_showIndex],
            bottomNavigationBar: AnimatedContainer(
              height: _bottomAppBarIsHidden
                  ? zeroHeight
                  : defaultNavigationBarHeight,
              duration: defaultTransitionDuration,
              child: AnimatedOpacity(
                opacity: _bottomAppBarIsHidden ? 0.0 : 1.0,
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
          "_bottomAppBarIsHidden": _bottomAppBarIsHidden,
        },
      );

  void _toggleShowOnScroll() => v(
        () {
          switch (_scrollController.position.userScrollDirection) {
            case ScrollDirection.idle:
              break;
            case ScrollDirection.forward:
              _bottomAppBarIsHidden
                  ? setState(() => _bottomAppBarIsHidden = false)
                  : null;
              break;
            case ScrollDirection.reverse:
              _bottomAppBarIsHidden
                  ? null
                  : setState(() => _bottomAppBarIsHidden = true);
              break;
          }
        },
        {
          "_bottomAppBarIsHidden": _bottomAppBarIsHidden,
          "userScrollDirection": _scrollController.position.userScrollDirection,
        },
      );
}
