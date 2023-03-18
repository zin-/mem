import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/main.dart';

const uriSchema = 'mem';
const appId = 'zin.playground.mem';
const actCounter = 'act_counters';
const memIdParamName = 'mem_id';

void backgroundCallback(Uri? uri) async {
  trace(uri);

  if (uri != null && uri.scheme == uriSchema && uri.host == appId) {
    await openDatabase();

    if (uri.pathSegments.contains(actCounter)) {
      final memId = uri.queryParameters[memIdParamName];

      if (memId != null) {
        await ActCounterService().increment(int.parse(memId));
      }
    }
  }
}

void initializeActCounter() {
  if (!Platform.isWindows) {
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }
}
