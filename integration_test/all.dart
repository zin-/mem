import 'package:flutter/foundation.dart';

import 'package:mem/database/database_factory.dart';
import 'package:mem/logger.dart';
import 'database/database_test.dart' as database_test;
import 'database/database_factory_test.dart' as database_factory_test;
import 'database/database-on_web_test.dart' as database_on_web_test;

import 'mem_repository_test.dart' as mem_repository_test;
import 'app_test.dart' as app_test;

void main() async {
  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  database_test.main();
  database_factory_test.main();
  if (kIsWeb) {
    database_on_web_test.main();
  }

  mem_repository_test.main();

  app_test.main();
}
