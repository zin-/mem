import 'package:flutter/material.dart';

import 'generated/l10n/app_localizations.dart';
import 'l10n/l10n.dart';
import 'features/logger/log_service.dart';
import 'router.dart';

class MemApplication extends StatelessWidget {
  final String? _initialPath;
  final String? _languageCode;

  const MemApplication({
    super.key,
    String? initialPath,
    String? languageCode,
  })  : _initialPath = initialPath,
        _languageCode = languageCode;

  @override
  Widget build(BuildContext context) => i(
        () => MaterialApp.router(
          routerConfig: buildRouter(_initialPath),
          onGenerateTitle: (context) => buildL10n(context).appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // ローカルでWindows向けにテストするときに必要
          locale: _languageCode == null ? null : Locale(_languageCode),
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: ThemeMode.system,
        ),
        {
          'initialPath': _initialPath,
          'languageCode': _languageCode,
        },
      );
}
