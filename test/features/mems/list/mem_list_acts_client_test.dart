// MemList → resumeActBy → ActsClient.resume の経路を、リスト画面フローに寄せて検証する。
// play のタップ自体は mem_list_item_test / actions_test で行う。
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' show setOnTest;
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/acts/act_service.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  ActService,
  ActRepository,
  ActQueryService,
  NotificationClient,
])
import 'mem_list_acts_client_test.mocks.dart';

void main() {
  late MockActService mockActService;
  late MockActRepository mockRepo;
  late MockActQueryService mockQuery;
  late MockNotificationClient mockNotification;
  late ActsClient client;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setOnTest(true);
  });

  setUp(() {
    ActsClient.resetSingleton();
    ActService.resetSingleton();
    mockActService = MockActService();
    mockRepo = MockActRepository();
    mockQuery = MockActQueryService();
    mockNotification = MockNotificationClient();
    client = ActsClient(
      actService: mockActService,
      actRepository: mockRepo,
      actQueryService: mockQuery,
      notificationClient: mockNotification,
    );
  });

  group('ActsClient.resume (paused 行の play と対応)', () {
    test('calls actService.resume and startActNotifications', () async {
      final whenTime = DateAndTime(2024, 7, 1, 15, 0);
      final entity = ActEntity(
        8,
        DateAndTime(2024, 7, 1, 15, 0),
        null,
        null,
        100,
        DateTime(2024, 7, 1),
        DateTime(2024, 7, 1),
        null,
      );
      when(mockActService.resume(any, any)).thenAnswer((_) async => entity);
      when(mockNotification.startActNotifications(any)).thenAnswer((_) async {});

      final saved = await client.resume(8, whenTime);

      verify(mockActService.resume(8, whenTime)).called(1);
      verify(mockNotification.startActNotifications(8)).called(1);
      expect(saved.value.memId, 8);
    });
  });
}
