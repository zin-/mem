import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/gui/colors.dart';
import 'package:mem/logger/log_service.dart';

class MemApplication extends StatelessWidget {
  final Widget home;
  final String? languageCode;

  const MemApplication(this.home, this.languageCode, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => i(
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
            home: home,
          ),
        ),
      );
}
