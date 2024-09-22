import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/router.dart';

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
        () => ProviderScope(
          child: MaterialApp.router(
            routerConfig: buildRouter(_initialPath),
            onGenerateTitle: (context) => buildL10n(context).appTitle,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // ローカルでWindows向けにテストするときに必要
            locale: _languageCode == null ? null : Locale(_languageCode),
            theme: ThemeData.light(useMaterial3: true),
          ),
        ),
        {
          'initialPath': _initialPath,
          'languageCode': _languageCode,
        },
      );
}
