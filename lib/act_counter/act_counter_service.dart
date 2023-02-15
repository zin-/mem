import 'package:flutter/services.dart';
import 'package:mem/act_counter/all.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';

// see android\app\src\main\kotlin\zin\playground\mem\ActCounterConfigure.kt
const methodChannelName = 'zin.playground.mem/act_counter';
const initializeMethodName = 'initialize';

class ActCounterService {
  // final ActRepository _actRepository;

  createNew(MemId memId) => t(
        {'memId': memId},
        () async {
          // final acts = await _actRepository.shipByMemId(memId);
          const methodChannel = MethodChannel(methodChannelName);
          final homeWidgetId =
              await methodChannel.invokeMethod(initializeMethodName);
          if (homeWidgetId != null) {
            saveWidgetData(
              "$homeWidgetId-memId",
              memId,
            );
            updateWidget();
          }
        },
      );

  ActCounterService._();

  // ActCounterService._(this._actRepository);

  static ActCounterService? _instance;

  factory ActCounterService({ActRepository? actRepository}) {
    var tmp = _instance;
    if (tmp == null) {
      _instance = tmp = ActCounterService._(
          // actRepository ?? ActRepository(),
          );
    }
    return tmp;
  }
}
