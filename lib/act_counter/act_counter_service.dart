import 'package:flutter/services.dart';
import 'package:mem/act_counter/all.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_repository_v2.dart';

// see android\app\src\main\kotlin\zin\playground\mem\ActCounterConfigure.kt
const methodChannelName = 'zin.playground.mem/act_counter';
const initializeMethodName = 'initialize';

class ActCounterService {
  final MemRepositoryV2 _memRepositoryV2;
  final ActRepository _actRepository;

  createNew(MemId memId) => t(
        {'memId': memId},
        () async {
          const methodChannel = MethodChannel(methodChannelName);
          final homeWidgetId =
              await methodChannel.invokeMethod(initializeMethodName);
          dev({'homeWidgetId': homeWidgetId});
          if (homeWidgetId != null) {
            await saveWidgetData(
              "memId-$homeWidgetId",
              memId,
            );

            final mem = await _memRepositoryV2.shipById(memId);
            final acts = await _actRepository.shipByMemId(memId);

            await saveWidgetData(
              "actCount-$memId",
              acts.length,
            );
            final lastUpdatedAt = acts
                .map((e) =>
                    e.updatedAt?.millisecondsSinceEpoch ??
                    e.createdAt!.millisecondsSinceEpoch)
                .fold<int>(
                  0,
                  (previousValue, element) =>
                      previousValue < element ? element : previousValue,
                )
                .toDouble();
            dev(lastUpdatedAt);
            final a = await saveWidgetData(
              "lastUpdatedAt-$memId",
              lastUpdatedAt,
            );
            dev(a);
            await saveWidgetData(
              "memName-$memId",
              mem.name,
            );

            await updateWidget();
          }
        },
      );

  ActCounterService._(this._memRepositoryV2, this._actRepository);

  static ActCounterService? _instance;

  factory ActCounterService({
    MemRepositoryV2? memRepositoryV2,
    ActRepository? actRepository,
  }) {
    var tmp = _instance;
    if (tmp == null) {
      _instance = tmp = ActCounterService._(
        memRepositoryV2 ?? MemRepositoryV2(),
        actRepository ?? ActRepository(),
      );
    }
    return tmp;
  }
}
