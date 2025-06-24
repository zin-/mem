import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/acts/act_service.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/values/constants.dart';
import 'package:mem/widgets/infinite_scroll.dart';
import 'package:mem/shared/entities_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'states.g.dart';

@riverpod
class ActEntities extends _$ActEntities
    with EntitiesStateMixin<SavedActEntity, int> {
  @override
  Iterable<SavedActEntity> build() => [];

  Future<Iterable<SavedActEntity>> fetch(int memId, Period period) => v(
        () async {
          final acts = await ActRepository().ship(
            memId: memId,
            period: period.toPeriod(
                DateAndTime.now(),
                ref.watch(preferencesProvider).value?[startOfDayKey] ??
                    defaultStartOfDay),
          );

          upsert(acts);

          return acts;
        },
        {
          'memId': memId,
          'period': period,
        },
      );

  Future<Iterable<SavedActEntity>> fetchLatestByMemIds(
    Iterable<int> memIds,
  ) =>
      v(
        () async {
          final latestActs = await ActService().fetchLatestByMemIds(memIds);

          upsert(latestActs);

          return latestActs;
        },
        {
          'memIds': memIds,
        },
      );

  Future<void> startActby(int memId) => v(
        () async {
          final now = DateAndTime.now();

          final startedAct = await ActsClient().start(memId, now);

          upsert([startedAct]);
        },
        {
          'memId': memId,
        },
      );

  Future<void> pauseByMemId(int memId) => v(
        () async {
          final now = DateAndTime.now();

          final updatedEntities = await ActsClient().pause(memId, now);

          upsert(updatedEntities);
        },
        {
          'memId': memId,
        },
      );

  Future<void> closeByMemId(int memId) => v(
        () async {
          final closed = await ActsClient().close(memId);

          if (closed != null) {
            remove([closed.id]);
          }
        },
        {'memId': memId},
      );

  Future<void> finishActby(int memId) => v(
        () async {
          final now = DateAndTime.now();

          final finishedAct = await ActsClient().finish(memId, now);

          upsert([finishedAct]);
        },
        {
          'memId': memId,
        },
      );

  Future<void> edit(SavedActEntity act) => v(
        () async {
          final editedAct = await ActsClient().edit(act);

          upsert([editedAct]);
        },
        {
          'act': act,
        },
      );

  Future<Iterable<SavedActEntity>> removeAsync(Iterable<int> ids) => v(
        () async {
          await Future.wait(ids.map((id) => ActsClient().delete(id)));

          return remove(ids);
        },
        {'ids': ids},
      );
}

@riverpod
Future<void> loadActList(Ref ref, int memId, Period period) => v(
      () async {
        await ref.watch(actEntitiesProvider.notifier).fetch(memId, period);
      },
      {
        'memId': memId,
        'period': period,
      },
    );

@riverpod
List<SavedActEntity> actList(Ref ref, int? memId) => d(
      () {
        if (ref.read(
            // ignore: avoid_manual_providers_as_generated_provider_dependency
            isUpdating(memId))) {
          ref.watch(
              // ignore: avoid_manual_providers_as_generated_provider_dependency
              isUpdating(memId));
        } else {
          Future.microtask(() async {
            ref.read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                isLoading(memId).notifier).updatedBy(true);

            final latest = await ActsClient().fetch(memId, 1);
            final c = ref.read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                currentPage(memId));

            ListWithTotalPage<SavedActEntity>? byPage;
            if (c != 1) {
              byPage = await ActsClient().fetch(memId, c);
            }

            ref.read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                isLoading(memId).notifier).updatedBy(false);
            ref.read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                isUpdating(memId).notifier).updatedBy(true);
            ref.read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                maxPage(memId).notifier).updatedBy(latest.totalPage);

            ref.read(actEntitiesProvider.notifier).upsert(
              [
                ...latest.list,
                if (byPage != null) ...byPage.list,
              ],
            );
          });
        }

        return ref
            .watch(actEntitiesProvider)
            .where(
              (actEntity) => memId == null || actEntity.value.memId == memId,
            )
            .where(
              (actEntity) => actEntity.value.period != null,
            )
            .sorted(
              (a, b) => b.value.period!.compareTo(a.value.period!),
            );
      },
      {
        'memId': memId,
      },
    );

@riverpod
Map<int, Act?>? latestActsByMem(Ref ref) => v(
      () => ref.watch(
        actEntitiesProvider.select(
          (value) => value
              .groupListsBy(
                (element) => element.value.memId,
              )
              .map(
                (key, value) => MapEntry(
                  key,
                  value
                      .sorted(
                        (a, b) => (b.value.period?.start ?? b.createdAt)
                            .compareTo(a.value.period?.start ?? a.createdAt),
                      )
                      .firstOrNull
                      ?.value,
                ),
              ),
        ),
      ),
    );
