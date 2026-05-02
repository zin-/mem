// MemList の再生（start / resume）から辿る ActService の分岐を検証する。
// 行の play を押す操作そのものは actions_test / mem_list_item_test で検証する。
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' show setOnTest;
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/acts/act_service.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart'
    show any, captureAny, verify, verifyNever, when;

@GenerateMocks([ActRepository, ActQueryService])
import 'mem_list_act_service_test.mocks.dart';

void main() {
  late MockActRepository mockRepo;
  late MockActQueryService mockQuery;
  late ActService service;

  ActEntity entityEchoAct(Act act, {int id = 99}) {
    final fixed = DateTime(2024, 6, 1);
    return ActEntity(
      act.memId,
      act.period?.start,
      act.period?.end,
      act.pausedAt,
      id,
      fixed,
      fixed,
      null,
    );
  }

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setOnTest(true);
  });

  setUp(() {
    ActService.resetSingleton();
    mockRepo = MockActRepository();
    mockQuery = MockActQueryService();
    service = ActService(
      actRepository: mockRepo,
      actQueryService: mockQuery,
    );
  });

  group('ActService.start (MemList で別Memを新規開始)', () {
    test('calls receive with active act for memId', () async {
      when(mockRepo.receive(any)).thenAnswer(
        (invocation) async =>
            entityEchoAct(invocation.positionalArguments.single as Act),
      );

      final whenTime = DateAndTime(2024, 3, 10, 12, 30);
      final result = await service.start(5, whenTime);

      verifyNever(mockRepo.replace(captureAny));
      final captured =
          verify(mockRepo.receive(captureAny)).captured.single as Act;
      expect(captured.memId, 5);
      expect(captured, isA<ActiveAct>());
      expect(result.memId, 5);
    });
  });

  group('ActService.resume (MemList で paused 行の play)', () {
    test('receive path when no paused rows', () async {
      when(mockQuery.fetchLatestAndPausedByMemIds(any)).thenAnswer(
        (_) async => <ActEntity>[],
      );
      when(mockRepo.receive(any)).thenAnswer(
        (invocation) async =>
            entityEchoAct(invocation.positionalArguments.single as Act, id: 1),
      );

      final whenTime = DateAndTime(2024, 4, 1, 8, 0);
      final out = await service.resume(2, whenTime);

      verify(mockQuery.fetchLatestAndPausedByMemIds([2])).called(1);
      verify(mockRepo.receive(captureAny)).called(1);
      verifyNever(mockRepo.replace(captureAny));
      expect(out.memId, 2);
    });

    test('receive path when latest is finished', () async {
      final now = DateTime(2024, 5, 1);
      final finished = ActEntity(
        3,
        DateAndTime(2024, 1, 1),
        DateAndTime(2024, 1, 2),
        null,
        10,
        now,
        now,
        null,
      );
      when(mockQuery.fetchLatestAndPausedByMemIds(any)).thenAnswer(
        (_) async => [finished],
      );
      when(mockRepo.receive(any)).thenAnswer(
        (invocation) async =>
            entityEchoAct(invocation.positionalArguments.single as Act, id: 11),
      );

      final whenTime = DateAndTime(2024, 5, 5, 9, 0);
      await service.resume(3, whenTime);

      verify(mockRepo.receive(captureAny)).called(1);
      verifyNever(mockRepo.replace(captureAny));
    });

    test('replace path when latest is paused', () async {
      final now = DateTime(2024, 5, 1);
      final paused = ActEntity(
        4,
        null,
        null,
        DateTime(2024, 4, 15, 18, 0),
        20,
        now,
        now,
        null,
      );
      when(mockQuery.fetchLatestAndPausedByMemIds(any)).thenAnswer(
        (_) async => [paused],
      );
      when(mockRepo.replace(any)).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.single as ActEntity,
      );

      final whenTime = DateAndTime(2024, 5, 10, 10, 0);
      final out = await service.resume(4, whenTime);

      verify(mockRepo.replace(captureAny)).called(1);
      verifyNever(mockRepo.receive(captureAny));
      expect(out.memId, 4);
    });

    test('uses sort comparator when multiple entities share memId', () async {
      final t = DateTime(2024, 5, 1);
      final older = ActEntity(
        6,
        null,
        null,
        DateTime(2024, 3, 1),
        1,
        DateTime(2024, 3, 1, 9),
        t,
        null,
      );
      final newer = ActEntity(
        6,
        null,
        null,
        DateTime(2024, 4, 1),
        2,
        DateTime(2024, 4, 1, 9),
        t,
        null,
      );
      when(mockQuery.fetchLatestAndPausedByMemIds(any))
          .thenAnswer((_) async => [older, newer]);
      when(mockRepo.replace(any)).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.single as ActEntity,
      );

      await service.resume(6, DateAndTime(2024, 6, 1, 12, 0));

      verify(mockRepo.replace(captureAny)).called(1);
    });
  });
}
