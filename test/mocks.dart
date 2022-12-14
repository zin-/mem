import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  MemRepository,
  MemRepositoryV2,
  MemItemRepository,
  NotificationRepository,
])
void main() {}
