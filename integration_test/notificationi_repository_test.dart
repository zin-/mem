import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/notification_repository.dart';

void main() {
  Logger(level: Level.verbose);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Create instance', () {
    test(
      ': no initialized',
      () {
        expect(
          () => NotificationRepository(),
          throwsA((e) => e is Exception),
        );
      },
      tags: 'Medium',
    );

    test(
      ': initialized',
      () {
        final initialized = NotificationRepository.initialize();

        final notificationRepository = NotificationRepository();

        expect(notificationRepository, initialized);
      },
      tags: 'Medium',
    );
  });
}
