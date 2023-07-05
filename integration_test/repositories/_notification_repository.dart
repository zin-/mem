import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/notifications/notification.dart';
import 'package:mem/notifications/notification_channel.dart';
import 'package:mem/notifications/notification_repository.dart';

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
                    OneTimeNotification(
                      1,
                      'title',
                      'body',
                      DateTime.now().add(const Duration(days: 1)),
                      jsonEncode({}),
                      [],
                      NotificationChannel(
                        'test channelId',
                        'test channelName',
                        'test channelDescription',
                      ),
                    ),
                  );

                  // dev(result);
                  // TODO 通知されていることをcheckする
                },
              );
            },
          );
        }
      },
    );
