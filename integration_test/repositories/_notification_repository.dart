import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logger/logger.dart';
import 'package:mem/repositories/notification_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Logger(level: Level.verbose);

  testNotificationRepository();
}

void testNotificationRepository() => group(
      'NotificationRepository test',
      () {
        if (Platform.isAndroid) {
          group(
            'Create instance',
            () {
              test(
                ': create instance',
                () {
                  final initialized = NotificationRepository();

                  expect(initialized, isA<NotificationRepository>());
                },
                tags: 'Small',
              );
            },
          );

          group(
            'Operating',
            () {
              late NotificationRepository notificationRepository;

              setUpAll(() {
                notificationRepository = NotificationRepository();
                notificationRepository.initialize();
              });

              testWidgets(
                ': receive',
                (widgetTester) async {
                  await notificationRepository.receive(
                    1,
                    'title',
                    DateTime.now().add(const Duration(days: 1)),
                  );

                  // dev(result);
                  // TODO 通知されていることをcheckする
                },
                tags: 'Medium',
              );
            },
          );
        }
      },
    );
