import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/list/act_list.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/body.dart';
import 'package:mem/mems/list/show_new_mem_fab.dart';
import 'package:mem/notifications/client.dart';

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
  static final _scrollController = ScrollController();
  final _pages = [
    MemListBody(_scrollController),
    const ActList(null),
  ];
  final _floatingActionButtons = [
    ShowNewMemFab(_scrollController),
    null,
  ];

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _showIndex = 0;

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return Scaffold(
            body: SafeArea(child: widget._pages[_showIndex]),
            floatingActionButton: widget._floatingActionButtons[_showIndex],
            bottomNavigationBar: NavigationBar(
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
          );
        },
        {"_showIndex": _showIndex},
      );
}
