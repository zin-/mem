import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/counter/act_counter_client.dart';
import 'package:mem/features/acts/counter/home_widget_accessor.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/logger_wrapper.dart';
import 'package:mem/features/logger/sentry_wrapper.dart';
import 'package:mem/notifications/flutter_local_notifications_wrapper.dart';
import 'package:mockito/annotations.dart';

bool randomBool() => Random().nextBool();

int randomInt([int max = 42949671]) => Random().nextInt(max);

@GenerateMocks([
  HomeWidgetAccessor,
  LoggerWrapper,
  FlutterLocalNotificationsWrapper,
  // FIXME RepositoryではなくTableをmockする
  //  Repositoryはシステム固有の処理であるのに対して、Tableは永続仮想をラップする役割を持つため
  ActCounterClient,
  SentryWrapper,
])
void main() {}

Widget buildTestApp(Widget widget) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // FIXME この仕組みはなくす
      onGenerateTitle: (context) => buildL10n(context).test,
      home: widget,
    );

Widget buildTestAppWithProvider(
  Widget widget, {
  List<Override>? overrides,
}) =>
    ProviderScope(
      overrides: overrides ?? [],
      child: buildTestApp(widget),
    );

class TestCase<INPUT, EXPECTED> {
  final INPUT input;
  final EXPECTED expected;
  final String? name;

  TestCase(this.input, this.expected, {this.name});
}

// Finders
final cancelTextFinder = find.text("Cancel");
