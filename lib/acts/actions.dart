import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/act_entity.dart';
import 'package:mem/repositories/act_repository.dart';

import 'client.dart';
import 'states.dart';

final _actsClient = ActsClient();
final _actRepository = ActRepository();

final loadActList =
    FutureProvider.autoDispose.family<List<SavedActEntity>, int?>(
  (ref, memId) => v(
    () async {
      // TODO 全件取得する場合、件数的な不安がある
      //  1週間分とかにしとくか？
      final acts = await _actRepository.ship(memId: memId);

      ref.watch(actsProvider.notifier).upsertAll(
            acts,
            (tmp, item) => tmp.id == item.id,
          );

      return acts;
    },
    {
      'memId': memId,
    },
  ),
);

final startActBy = Provider.autoDispose.family<Act, int>(
  (ref, memId) => v(
    () {
      final now = DateAndTime.now();

      _actsClient.start(memId, now).then(
            (startedAct) => v(
              () => ref.read(actsProvider.notifier).upsertAll(
                [startedAct],
                (tmp, item) => tmp.id == item.id,
              ),
              startedAct,
            ),
          );

      return Act(memId, DateAndTimePeriod(start: now));
    },
    memId,
  ),
);

final finishActBy = Provider.autoDispose.family<SavedActEntity, int>(
  (ref, memId) => v(
    () {
      final now = DateAndTime.now();
      final finishingAct = ref.read(activeActsProvider).singleWhere(
            (act) => act.memId == memId,
          );

      _actsClient
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

      return finishingAct;
    },
    memId,
  ),
);
