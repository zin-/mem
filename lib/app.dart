import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/listAndDetails/colors.dart';
import 'package:mem/view/mems/mem_list/mem_list_page.dart';

class MemApplication extends StatelessWidget {
  final String? languageCode;

  const MemApplication(this.languageCode, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => ProviderScope(
          child: MaterialApp(
            onGenerateTitle: (context) => L10n(context).appTitle(),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            locale: languageCode == null ? null : Locale(languageCode!),
            theme: ThemeData(
              primarySwatch: primaryColor,
              bottomAppBarTheme: const BottomAppBarTheme(
                color: primaryColor,
              ),
            ),
            home: MemListPage(),
          ),
        ),
      );
}
