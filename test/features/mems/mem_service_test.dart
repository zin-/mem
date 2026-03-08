import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
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
        final mem = MemEntityV1(Mem(null, 'Test Mem', null, null));
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

        final savedMem = SavedMemEntityV1({
          'id': testMemId,
          'name': 'Test Mem',
          'doneAt': null,
          'notifyOn': null,
          'notifyAt': null,
          'endOn': null,
          'endAt': null,
          'createdAt': DateTime.now(),
          'updatedAt': null,
          'archivedAt': null,
        });

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

        when(mockMemRepository.receiveV2(any))
            .thenAnswer((_) async => savedMem.toEntityV2());
        when(mockMemNotificationRepository.wasteV2(
          memId: anyNamed('memId'),
          type: anyNamed('type'),
          condition: anyNamed('condition'),
        )).thenAnswer((_) async => []);
        when(mockMemRelationRepository.wasteV2(
                condition: anyNamed('condition')))
            .thenAnswer((_) async => []);
        when(mockTargetRepository.wasteV2(condition: anyNamed('condition')))
            .thenAnswer((_) async => []);
        when(mockMemNotificationRepository.wasteV2(
          memId: anyNamed('memId'),
          type: anyNamed('type'),
          condition: anyNamed('condition'),
        )).thenAnswer((_) async => []);
        when(mockMemRelationRepository.wasteV2(
                condition: anyNamed('condition')))
            .thenAnswer((_) async => []);
        when(mockTargetRepository.wasteV2(condition: anyNamed('condition')))
            .thenAnswer((_) async => []);
        when(mockTargetRepository.receiveV2(any))
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
        verify(mockTargetRepository.receiveV2(any)).called(1);
      });

      test('should not call _targetRepository.receive when target is null',
          () async {
        // Arrange
        const testMemId = 1;
        final mem = MemEntityV1(Mem(null, 'Test Mem', null, null));
        final memItems = <MemItemEntityV1>[];
        final memNotifications = <MemNotificationEntityV1>[];
        final target = null;
        final memRelations = <MemRelationEntityV1>[];

        final savedMem = SavedMemEntityV1({
          'id': testMemId,
          'name': 'Test Mem',
          'doneAt': null,
          'notifyOn': null,
          'notifyAt': null,
          'endOn': null,
          'endAt': null,
          'createdAt': DateTime.now(),
          'updatedAt': null,
          'archivedAt': null,
        });

        when(mockMemRepository.receiveV2(any))
            .thenAnswer((_) async => savedMem.toEntityV2());
        when(mockMemNotificationRepository.wasteV2(
          memId: anyNamed('memId'),
          type: anyNamed('type'),
          condition: anyNamed('condition'),
        )).thenAnswer((_) async => []);
        when(mockMemRelationRepository.wasteV2(
                condition: anyNamed('condition')))
            .thenAnswer((_) async => []);
        when(mockTargetRepository.wasteV2(condition: anyNamed('condition')))
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
        verifyNever(mockTargetRepository.receiveV2(any));
      });

      test('should not call _targetRepository.receive when target value is 0',
          () async {
        // Arrange
        const testMemId = 1;
        final mem = MemEntityV1(Mem(null, 'Test Mem', null, null));
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

        final savedMem = SavedMemEntityV1({
          'id': testMemId,
          'name': 'Test Mem',
          'doneAt': null,
          'notifyOn': null,
          'notifyAt': null,
          'endOn': null,
          'endAt': null,
          'createdAt': DateTime.now(),
          'updatedAt': null,
          'archivedAt': null,
        });

        when(mockMemRepository.receiveV2(any))
            .thenAnswer((_) async => savedMem.toEntityV2());
        when(mockMemNotificationRepository.wasteV2(
          memId: anyNamed('memId'),
          type: anyNamed('type'),
          condition: anyNamed('condition'),
        )).thenAnswer((_) async => []);
        when(mockMemRelationRepository.wasteV2(
                condition: anyNamed('condition')))
            .thenAnswer((_) async => []);
        when(mockTargetRepository.wasteV2(condition: anyNamed('condition')))
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
        verifyNever(mockTargetRepository.receiveV2(any));
      });
    });
  });
}
