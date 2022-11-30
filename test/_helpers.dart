import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/gui/l10n.dart';

/// ref.
/// - https://testing.googleblog.com/2010/12/test-sizes.html
// enum型では文字列を返却することができないためclassで定義する
abstract class TestSize {
  /// 他システムへの依存が排除されたテスト
  /// 単一のランタイムで実行可能
  ///
  /// e.g.
  /// - Database(local), File system, System property access禁止
  /// - Multi thread, Sleep statement禁止
  static const small = 'Small';

  /// プラットフォーム外への依存が排除されたテスト
  /// 単一のプラットフォームで実行可能
  ///
  /// e.g.
  /// - Local Database, File system, System property access許可
  /// - Multi thread, Sleep statement許可
  /// - View element許可
  static const medium = 'Medium';

  /// すべての依存を排除しないテスト
  ///
  /// e.g.
  /// - External system, Database, Network access許可
  static const large = 'Large';

  TestSize._();
}

Future<void> runTestWidget(WidgetTester widgetTester, Widget widget) =>
    widgetTester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        onGenerateTitle: (context) => L10n(context).test(),
        home: widget,
      ),
    );
