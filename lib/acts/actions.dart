import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'client.dart';
import 'states.dart';

part 'actions.g.dart';

final _actsClient = ActsClient();
final _actRepository = ActRepository();

final loadActList = FutureProvider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      // FIXME 全件取得する場合、件数的な不安がある
      //  1週間分とかにしとくか？
      final acts = await _actRepository.ship(memId: memId);

      ref.watch(actsProvider.notifier).upsertAll(
            acts,
            (tmp, item) => tmp.id == item.id,
          );
    },
    {
      'memId': memId,
    },
  ),
);

@riverpod
Future<void> startActByV2(Ref ref, int memId) => v(
      () async {
        final now = DateAndTime.now();

        final startedAct = await _actsClient.start(memId, now);

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

      _actsClient.start(memId, now).then(
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

final finishActBy = Provider.autoDispose.family<int, int>(
  (ref, memId) => v(
    () {
      final now = DateAndTime.now();
      final finishingAct = ref.read(activeActsProvider).singleWhere(
            (act) => act.value.memId == memId,
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

      return finishingAct.id;
    },
    memId,
  ),
);
