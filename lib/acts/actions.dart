import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/acts/line_chart/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/settings/preference/keys.dart';
import 'package:mem/settings/states.dart';
import 'package:mem/values/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'client.dart';
import 'states.dart';

part 'actions.g.dart';

@riverpod
Future<void> loadActList(Ref ref, int memId, Period period) => v(
      () async {
        final acts = await ActRepository().ship(
          memId: memId,
          period: period.toPeriod(
              DateAndTime.now(),
              ref.watch(preferencesProvider).value?[startOfDayKey] ??
                  defaultStartOfDay),
        );

        ref
            .watch(
              // ignore: avoid_manual_providers_as_generated_provider_dependency
              actsProvider.notifier,
            )
            .upsertAll(
              acts,
              (tmp, item) => tmp.id == item.id,
            );
      },
      {
        'memId': memId,
        'period': period,
      },
    );

@riverpod
Future<void> startActByV2(Ref ref, int memId) => v(
      () async {
        final now = DateAndTime.now();

        final startedAct = await ActsClient().start(memId, now);

        // ignore: avoid_manual_providers_as_generated_provider_dependency
        ref.read(actsProvider.notifier).upsertAll(
          [startedAct],
          (tmp, item) => tmp.id == item.id,
        );
      },
      {
        'memId': memId,
      },
    );

final startActBy = Provider.autoDispose.family<Act, int>(
  (ref, memId) => v(
    () {
      final now = DateAndTime.now();

      ActsClient().start(memId, now).then(
            (startedAct) => v(
              () => ref.read(actsProvider.notifier).upsertAll(
                [startedAct],
                (tmp, item) => tmp.id == item.id,
              ),
              startedAct,
            ),
          );

      return Act.by(memId, now);
    },
    memId,
  ),
);

final finishActBy = Provider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () {
      final now = DateAndTime.now();

      ActsClient()
          .finish(
            memId,
            now,
          )
          .then((finishedAct) => v(
                () => ref.read(actsProvider.notifier).upsertAll(
                  [finishedAct],
                  (tmp, item) => tmp.id == item.id,
                ),
                finishedAct,
              ));
    },
    memId,
  ),
);
