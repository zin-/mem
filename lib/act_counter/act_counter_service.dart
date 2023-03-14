import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:mem/act_counter/all.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
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
          if (homeWidgetId != null) {
            await saveWidgetData(
              "memId-$homeWidgetId",
              memId,
            );

            await updateActCounter(memId);
          }
        },
      );

  increment(int memId) => t(
        {'memId': memId},
        () async {
          await _actRepository.receive(Act(
              memId,
              DateAndTimePeriod(
                start: DateAndTime.now(),
                end: DateAndTime.now(),
              )));

          await updateActCounter(memId);
        },
      );

  updateActCounter(MemId memId) => v(
        {'memId': memId},
        () async {
          final mem = await _memRepositoryV2.shipById(memId);

          final now = DateAndTime.now();
          DateAndTime start = DateAndTime(
            now.year,
            now.month,
            now.hour < 5 ? now.day - 1 : now.day,
            5,
            0,
          );
          final acts = await _actRepository.shipByMemId(
            memId,
            period: DateAndTimePeriod(
              start: start,
              end: start.add(const Duration(days: 1)),
            ),
          );

          await saveWidgetData(
            "actCount-$memId",
            acts.length,
          );

          final lastAct = acts
              .sorted(
                (a, b) => (a.updatedAt ?? a.createdAt!)
                    .compareTo(b.updatedAt ?? b.createdAt!),
              )
              .lastOrNull;
          final lastUpdatedAtSeconds = lastAct == null
              ? null
              : (lastAct.period.end ?? lastAct.period.start!)
                  .millisecondsSinceEpoch
                  .toDouble();
          await saveWidgetData(
            "lastUpdatedAtSeconds-$memId",
            lastUpdatedAtSeconds,
          );
          await saveWidgetData(
            "memName-$memId",
            mem.name,
          );

          await updateWidget();
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
