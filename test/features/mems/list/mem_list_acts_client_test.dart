// MemList → resumeActBy → ActsClient.resume の経路を、リスト画面フローに寄せて検証する。
// play のタップ自体は mem_list_item_test / actions_test で行う。
import 'package:drift/drift.dart' show Migrator;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act, Mem;
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/acts/act_service.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/singleton.dart';
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
      when(mockNotification.startActNotifications(any))
          .thenAnswer((_) async {});

      final saved = await client.resume(8, whenTime);

      verify(mockActService.resume(8, whenTime)).called(1);
      verify(mockNotification.startActNotifications(8)).called(1);
      expect(saved.value.memId, 8);
    });
  });

  group('ActsClient re-registers mem notifications', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Migrator(db).createAll();
      DriftDatabaseAccessor.reset();
      Singleton.override<DriftDatabaseAccessor>(
        DriftDatabaseAccessor.withDatabase(db),
      );
    });

    tearDown(() async {
      await db.close();
      DriftDatabaseAccessor.reset();
    });

    Future<int> insertMem() async => (await db.into(db.mems).insertReturning(
              MemsCompanion.insert(name: 'm', createdAt: DateTime(2024, 8, 1)),
            ))
        .id;

    test('after finish', () async {
      final whenTime = DateAndTime(2024, 8, 1, 10, 30);
      final memId = await insertMem();
      final entity = ActEntity(
        memId,
        whenTime,
        whenTime,
        null,
        101,
        DateTime(2024, 8, 1),
        DateTime(2024, 8, 1),
        null,
        actKind: ActKind.finished,
      );
      when(mockActService.finish(any, any)).thenAnswer((_) async => entity);
      when(mockNotification.cancelActNotification(any))
          .thenAnswer((_) async {});
      when(mockNotification.registerMemNotifications(any))
          .thenAnswer((_) async => null);
      when(mockNotification.setNotificationAfterInactivity())
          .thenAnswer((_) async {});

      await client.finish(memId, whenTime);

      verify(mockActService.finish(memId, whenTime)).called(1);
      verify(mockNotification.cancelActNotification(memId)).called(1);
      final registered = verify(
        mockNotification.registerMemNotifications(captureAny),
      ).captured.single as Mem;
      expect(registered.id, memId);
      verify(mockNotification.setNotificationAfterInactivity()).called(1);
    });

    test('after skip', () async {
      final whenTime = DateAndTime(2024, 8, 1, 9, 0);
      final memId = await insertMem();
      final entity = ActEntity(
        memId,
        whenTime,
        whenTime,
        null,
        101,
        DateTime(2024, 8, 1),
        DateTime(2024, 8, 1),
        null,
        actKind: ActKind.skipped,
      );
      when(mockActService.skip(any, any)).thenAnswer((_) async => entity);
      when(mockNotification.cancelActNotification(any))
          .thenAnswer((_) async {});
      when(mockNotification.registerMemNotifications(any))
          .thenAnswer((_) async => null);
      when(mockNotification.setNotificationAfterInactivity())
          .thenAnswer((_) async {});

      final saved = await client.skip(memId, whenTime);

      verify(mockActService.skip(memId, whenTime)).called(1);
      verify(mockNotification.cancelActNotification(memId)).called(1);
      final registered = verify(
        mockNotification.registerMemNotifications(captureAny),
      ).captured.single as Mem;
      expect(registered.id, memId);
      verify(mockNotification.setNotificationAfterInactivity()).called(1);
      expect(saved.value.actKind, ActKind.skipped);
    });

    test('after edit', () async {
      final whenTime = DateAndTime(2024, 8, 1, 11, 0);
      final memId = await insertMem();
      final entity = ActEntity(
        memId,
        whenTime,
        whenTime,
        null,
        101,
        DateTime(2024, 8, 1),
        DateTime(2024, 8, 1),
        null,
        actKind: ActKind.finished,
      );
      when(mockActService.edit(any)).thenAnswer((_) async => entity);
      when(mockNotification.cancelActNotification(any))
          .thenAnswer((_) async {});
      when(mockNotification.registerMemNotifications(any))
          .thenAnswer((_) async => null);

      await client.edit(SavedActEntityV1.fromEntityV2(entity));

      verify(mockActService.edit(any)).called(1);
      verify(mockNotification.cancelActNotification(memId)).called(1);
      final registered = verify(
        mockNotification.registerMemNotifications(captureAny),
      ).captured.single as Mem;
      expect(registered.id, memId);
    });

    test('after delete', () async {
      final whenTime = DateAndTime(2024, 8, 1, 12, 0);
      final memId = await insertMem();
      final entity = ActEntity(
        memId,
        whenTime,
        whenTime,
        null,
        101,
        DateTime(2024, 8, 1),
        DateTime(2024, 8, 1),
        null,
        actKind: ActKind.finished,
      );
      when(mockRepo.waste(id: anyNamed('id')))
          .thenAnswer((_) async => [entity]);
      when(mockNotification.cancelActNotification(any))
          .thenAnswer((_) async {});
      when(mockNotification.registerMemNotifications(any))
          .thenAnswer((_) async => null);

      await client.delete(entity.id);

      verify(mockRepo.waste(id: entity.id)).called(1);
      verify(mockNotification.cancelActNotification(memId)).called(1);
      final registered = verify(
        mockNotification.registerMemNotifications(captureAny),
      ).captured.single as Mem;
      expect(registered.id, memId);
    });
  });
}
