import 'package:flutter/foundation.dart';

import 'database/database_test.dart' as database_test;
import 'database/database_factory_test.dart' as database_factory_test;
import 'database/database-on_web_test.dart' as database_on_web_test;
import 'app_test.dart' as app_test;
import 'mem_repository_test.dart' as mem_repository_test;

void main() async {
  database_test.main();
  database_factory_test.main();
  if (kIsWeb) {
    database_on_web_test.main();
  }

  mem_repository_test.main();

  app_test.main();
}
