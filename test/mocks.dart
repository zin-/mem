import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/notification_repository.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  MemRepository,
  MemItemRepository,
  NotificationRepository,
])
void main() {}
