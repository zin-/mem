import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/colors.dart';
import 'package:mem/views/mem_list/mem_list_page.dart';

class MemApplication extends StatelessWidget {
  const MemApplication({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => ProviderScope(
          child: MaterialApp(
            // title: 'Mem',
            onGenerateTitle: (context) => L10n(context).appTitle(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              primarySwatch: primaryColor,
              bottomAppBarTheme: const BottomAppBarTheme(
                color: primaryColor,
              ),
            ),
            home: const MemListPage(),
          ),
        ),
      );
}
