import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/list/act_list_view.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/body.dart';
import 'package:mem/mems/list/show_new_mem_fab.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/values/colors.dart';

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
              theme: ThemeData(
                primarySwatch: primaryColor,
                bottomAppBarTheme: const BottomAppBarTheme(
                  color: primaryColor,
                ),
              ),
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
    const ActListView(),
  ];
  final floatingActionButtons = [
    ShowNewMemFab(_scrollController),
    // TODO 不要か？
    //  このときにやれるPrimary actionがないか検討する
    null,
  ];

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => v(
        () => Scaffold(
          body: SafeArea(child: widget._pages[_selectedIndex]),
          floatingActionButton: widget.floatingActionButtons[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (value) => setState(() {
              _selectedIndex = value;
            }),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.list), label: "list"),
              NavigationDestination(
                  icon: Icon(Icons.playlist_play), label: "acts"),
            ],
          ),
        ),
        [_selectedIndex],
      );
}
