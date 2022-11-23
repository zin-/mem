import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/notifications/notification_repository.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
            tags: TestSize.small,
          );

          group('Initialize', () {
            test(
              ': success',
              () async {
                final initialized = await NotificationRepository().initialize(
                  (id, actionId, input, payload) {},
                  null,
                );

                expect(initialized, true);
              },
              tags: TestSize.small,
            );

            test(
              ': twice',
              () async {
                final initialized = await NotificationRepository().initialize(
                  (id, actionId, input, payload) {},
                  null,
                );
                final initialized2 = await NotificationRepository().initialize(
                  (id, actionId, input, payload) {},
                  null,
                );

                expect(initialized, initialized2);
              },
              tags: TestSize.small,
            );
          });

          group(
            'Operating',
            () {
              late NotificationRepository notificationRepository;

              setUpAll(() {
                notificationRepository = NotificationRepository();
                notificationRepository.initialize(
                  (id, actionId, input, payload) {},
                  null,
                );
              });

              testWidgets(
                ': receive',
                (widgetTester) async {
                  await notificationRepository.receive(
                    1,
                    'title',
                    DateTime.now().add(const Duration(days: 1)),
                    [],
                    'test channelId',
                    'test channelName',
                    'test channelDescription',
                  );

                  // dev(result);
                  // TODO 通知されていることをcheckする
                },
                tags: TestSize.medium,
              );
            },
          );
        }
      },
    );
