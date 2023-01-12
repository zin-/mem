import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mem/logger/i/api.dart';
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) {
    final now = DateTime.now();

    return Future.wait<bool?>([
      HomeWidget.saveWidgetData(
        'title',
        'Updated from Background',
      ),
      HomeWidget.saveWidgetData(
        'message',
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      ),
      HomeWidget.updateWidget(
        name: 'HomeWidgetExampleProvider',
        iOSName: 'HomeWidgetExample',
      ),
    ]).then((value) {
      return !value.contains(false);
    });
  });
}

void backgroundCallback(Uri? uri) async {
  trace(uri);

  if (uri?.host == 'titleclicked') {
    const selectedGreeting = 'Hello';

    await HomeWidget.saveWidgetData<String>('title', selectedGreeting);
    await HomeWidget.updateWidget(
        name: 'HomeWidgetExampleProvider', iOSName: 'HomeWidgetExample');
  }
}

void initializeActCounter() {
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  HomeWidget.registerBackgroundCallback(backgroundCallback);
}

void checkForWidgetLaunch() {
  HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget);
}

bool _launchedFromWidget(Uri? uri) {
  trace('uri: $uri');

  return uri != null;
}

Future sendData() async {
  try {
    return Future.wait([
      HomeWidget.saveWidgetData<String>('title', 'Act counter title'),
      HomeWidget.saveWidgetData<String>('message', 'Act counter message'),
    ]);
  } on PlatformException catch (exception) {
    debugPrint('Error Sending Data. $exception');
  }
}
