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
          test(
            'Create instance',
            () {
              final instance = NotificationRepository();

              expect(instance, isA<NotificationRepository>());
            },
            tags: 'Small',
          );

          group('Initialize', () {
            test(
              ': success',
              () async {
                final initialized = await NotificationRepository().initialize();

                expect(initialized, true);
              },
              tags: 'Small',
            );

            test(
              ': twice',
              () async {
                final initialized = await NotificationRepository().initialize();
                final initialized2 =
                    await NotificationRepository().initialize();

                expect(initialized, initialized2);
              },
              tags: 'Small',
            );
          });

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
                    [],
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
