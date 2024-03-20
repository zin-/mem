import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act_counter/act_counter_repository.dart';
import 'package:mem/act_counter/act_counter_client.dart';
import 'package:mem/act_counter/home_widget_accessor.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/logger_wrapper.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/notifications/wrapper.dart';
import 'package:mockito/annotations.dart';

export 'helpers.mocks.dart';

bool randomBool() => Random().nextBool();

int randomInt([int max = 42949671]) => Random().nextInt(max);

@GenerateMocks([
  HomeWidgetAccessor,
  LoggerWrapper,
  NotificationsWrapper,
  // FIXME RepositoryではなくTableをmockする
  //  Repositoryはシステム固有の処理であるのに対して、Tableは永続仮想をラップする役割を持つため
  NotificationRepository,
  ActCounterRepository,
  ActCounterClient,
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

class TestCaseV2<I> {
  final I input;
  final dynamic expected;
  final String? name;

  TestCaseV2(this.input, this.expected, {this.name});
}

class TestCase<T> {
  final String name;
  final T input;
  final Function(T input) verify;

  TestCase(this.name, this.input, this.verify);
}

// Finders
final cancelTextFinder = find.text("Cancel");
