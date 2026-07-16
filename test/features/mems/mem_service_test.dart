import 'package:flutter_test/flutter_test.dart';
import '../../entity_factories.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'mem_service_test.mocks.dart';

@GenerateMocks([
  MemRepository,
  MemItemRepository,
  MemNotificationRepository,
  TargetRepository,
  MemRelationRepository,
])
void main() {
  late MockMemRepository mockMemRepository;
  late MockMemItemRepository mockMemItemRepository;
  late MockMemNotificationRepository mockMemNotificationRepository;
  late MockTargetRepository mockTargetRepository;
  late MockMemRelationRepository mockMemRelationRepository;
  late MemService memService;

  setUp(() {
    mockMemRepository = MockMemRepository();
    mockMemItemRepository = MockMemItemRepository();
    mockMemNotificationRepository = MockMemNotificationRepository();
    mockTargetRepository = MockTargetRepository();
    mockMemRelationRepository = MockMemRelationRepository();

    memService = MemService(
      memRepository: mockMemRepository,
      memItemRepository: mockMemItemRepository,
      memNotificationRepository: mockMemNotificationRepository,
      targetRepository: mockTargetRepository,
      memRelationRepository: mockMemRelationRepository,
    );
  });

  group('MemService.save', () {
    group('_targetRepository.receive', () {
      test(
          'should call _targetRepository.receive when target is not null and value is not 0 and target is not SavedTargetEntity',
          () async {
        // Arrange
        const testMemId = 1;
        final mem = MemViewData.newMem();
        final memItems = <MemItemEntityV1>[];
        final memNotifications = <MemNotificationEntityV1>[];
        final target = TargetEntityV1(
          Target(
            memId: null,
            targetType: TargetType.equalTo,
            targetUnit: TargetUnit.count,
            value: 10, // 0でない値
            period: Period.aDay,
          ),
        );
        final memRelations = <MemRelationEntityV1>[];

        final savedMemEntity = savedMem(
            id: testMemId, name: 'Test Mem', createdAt: DateTime.now());

        final savedTarget = TargetEntity(
          testMemId,
          TargetType.equalTo,
          TargetUnit.count,
          10,
          Period.aDay,
          1,
          DateTime.now(),
          null,
          null,
        );

        when(mockMemRepository.receive(any))
            .thenAnswer((_) async => savedMemEntity);
        when(mockMemNotificationRepository.waste(
          memId: anyNamed('memId'),
          type: anyNamed('type'),
        )).thenAnswer((_) async => []);
        when(mockMemRelationRepository.waste(
          sourceMemId: anyNamed('sourceMemId'),
        )).thenAnswer((_) async => []);
        when(mockTargetRepository.waste(memId: anyNamed('memId')))
            .thenAnswer((_) async => []);
        when(mockMemNotificationRepository.waste(
          memId: anyNamed('memId'),
          type: anyNamed('type'),
        )).thenAnswer((_) async => []);
        when(mockMemRelationRepository.waste(
          sourceMemId: anyNamed('sourceMemId'),
        )).thenAnswer((_) async => []);
        when(mockTargetRepository.waste(memId: anyNamed('memId')))
            .thenAnswer((_) async => []);
        when(mockTargetRepository.receive(any))
            .thenAnswer((_) async => savedTarget);

        // Act
        await memService.save((
          mem,
          memItems,
          memNotifications,
          target,
          memRelations,
        ));

        // Assert
        verify(mockTargetRepository.receive(any)).called(1);
      });

      test('should not call _targetRepository.receive when target is null',
          () async {
        // Arrange
        const testMemId = 1;
        final mem = MemViewData.newMem();
        final memItems = <MemItemEntityV1>[];
        final memNotifications = <MemNotificationEntityV1>[];
        final target = null;
        final memRelations = <MemRelationEntityV1>[];

        final savedMemEntity = savedMem(
            id: testMemId, name: 'Test Mem', createdAt: DateTime.now());

        when(mockMemRepository.receive(any))
            .thenAnswer((_) async => savedMemEntity);
        when(mockMemNotificationRepository.waste(
          memId: anyNamed('memId'),
          type: anyNamed('type'),
        )).thenAnswer((_) async => []);
        when(mockMemRelationRepository.waste(
          sourceMemId: anyNamed('sourceMemId'),
        )).thenAnswer((_) async => []);
        when(mockTargetRepository.waste(memId: anyNamed('memId')))
            .thenAnswer((_) async => []);

        // Act
        await memService.save((
          mem,
          memItems,
          memNotifications,
          target,
          memRelations,
        ));

        // Assert
        verifyNever(mockTargetRepository.receive(any));
      });

      test('should not call _targetRepository.receive when target value is 0',
          () async {
        // Arrange
        const testMemId = 1;
        final mem = MemViewData.newMem();
        final memItems = <MemItemEntityV1>[];
        final memNotifications = <MemNotificationEntityV1>[];
        final target = TargetEntityV1(
          Target(
            memId: null,
            targetType: TargetType.equalTo,
            targetUnit: TargetUnit.count,
            value: 0, // 0の値
            period: Period.aDay,
          ),
        );
        final memRelations = <MemRelationEntityV1>[];

        final savedMemEntity = savedMem(
            id: testMemId, name: 'Test Mem', createdAt: DateTime.now());

        when(mockMemRepository.receive(any))
            .thenAnswer((_) async => savedMemEntity);
        when(mockMemNotificationRepository.waste(
          memId: anyNamed('memId'),
          type: anyNamed('type'),
        )).thenAnswer((_) async => []);
        when(mockMemRelationRepository.waste(
          sourceMemId: anyNamed('sourceMemId'),
        )).thenAnswer((_) async => []);
        when(mockTargetRepository.waste(memId: anyNamed('memId')))
            .thenAnswer((_) async => []);

        // Act
        await memService.save((
          mem,
          memItems,
          memNotifications,
          target,
          memRelations,
        ));

        // Assert
        verifyNever(mockTargetRepository.receive(any));
      });
    });
  });
}
