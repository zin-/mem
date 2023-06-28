import 'dart:math';

import 'package:mem/act_counter/act_counter_repository.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/act_counter/home_widget_accessor.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/logger/logger_wrapper.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mockito/annotations.dart';

bool randomBool() => Random().nextBool();

int randomInt([int max = 4294967296]) => Random().nextInt(max);

@GenerateMocks([
  // FIXME RepositoryではなくTableをmockする
  //  Repositoryはシステム固有の処理であるのに対して、Tableは永続仮想をラップする役割を持つため
  HomeWidgetAccessor,
  LoggerWrapper,
  MemRepository,
  MemItemRepository,
  NotificationRepository,
  ActRepository,
  ActCounterRepository,
  ActCounterService,
])
void main() {}

class TestCase<T> {
  final String name;
  final T input;
  final Function(T input) verify;

  TestCase(this.name, this.input, this.verify);
}
