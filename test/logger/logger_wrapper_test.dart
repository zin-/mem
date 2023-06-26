import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/logger_wrapper.dart';

void main() {
  final loggerWrapper = LoggerWrapper();

  for (var level in Level.values) {
    group('level: $level', () {
      test(
        'log',
        () {
          loggerWrapper.log(level, 'test log');

          // FIXME ログが出力されたことが、テストとして確認できていない
          //  目視確認とエラーが発生していないことの確認はできているため、
          //  最低限のテストはできているものとしている状態
        },
      );

      test(
        'with Exception',
        () {
          loggerWrapper.log(
            level,
            'exception log',
            Exception('exception message'),
          );

          // FIXME ログが出力されたことが、テストとして確認できていない
          //  目視確認とエラーが発生していないことの確認はできているため、
          //  最低限のテストはできているものとしている状態
        },
      );

      test(
        'with StackTrace',
        () {
          loggerWrapper.log(
            level,
            'stackTrace log',
            Exception('exception message'),
            StackTrace.current,
          );

          // FIXME ログが出力されたことが、テストとして確認できていない
          //  目視確認とエラーが発生していないことの確認はできているため、
          //  最低限のテストはできているものとしている状態
        },
      );
    });
  }
}
