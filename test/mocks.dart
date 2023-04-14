import 'package:mem/act_counter/act_counter_repository.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  // FIXME RepositoryではなくTableをmockする
  //  Repositoryはシステム固有の処理であるのに対して、Tableは永続仮想をラップする役割を持つため
  MemRepository,
  MemItemRepository,
  NotificationRepository,
  ActRepository,
  ActCounterRepository,
])
void main() {}
