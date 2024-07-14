import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mem/router.dart';

class MemApplication extends StatelessWidget {
  final String? initialPath;

  const MemApplication({super.key, this.initialPath});

  @override
  Widget build(BuildContext context) => ProviderScope(
        child: MaterialApp.router(
          routerConfig: buildRouter(initialPath),
          onGenerateTitle: (context) => buildL10n(context).appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // TODO 必要？
          // locale: languageCode == null ? null : Locale(languageCode!),
          theme: ThemeData.light(useMaterial3: true),
        ),
      );
}
