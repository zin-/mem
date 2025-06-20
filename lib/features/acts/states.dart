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
  // ignore: avoid_manual_providers_as_generated_provider_dependency
  Iterable<SavedActEntity> build() => ref.watch(actsProvider);

  // TODO actsProviderから脱却したら削除する
  @override
  Iterable<SavedActEntity> upsert(Iterable<SavedActEntity> entities) => v(
        () {
          ref
              .read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                actsProvider.notifier,
              )
              .upsertAll(
                entities,
                (c, u) => c.id == u.id,
              );

          return entities;
        },
        {
          'entities': entities,
        },
      );

  // TODO actsProviderから脱却したら削除する
  @override
  Iterable<SavedActEntity> remove(Iterable<int> ids) => v(
        () {
          ref
              .read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                actsProvider.notifier,
              )
              .removeWhere((e) => ids.contains(e.id));

          return super.remove(ids);
        },
        {'ids': ids},
      );

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
          await Future.wait(ids.map((id) => _actsClient.delete(id)));

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

final _actsClient = ActsClient();

final actsProvider = StateNotifierProvider<
    ListValueStateNotifier<SavedActEntity>, List<SavedActEntity>>(
  (ref) => v(() => ListValueStateNotifier([])),
);

@riverpod
class ActsV2 extends _$ActsV2 {
  final _actsClient = ActsClient();
  final _actService = ActService();

  @override
  Future<Iterable<SavedActEntity>> build() async {
    // ignore: avoid_manual_providers_as_generated_provider_dependency
    return ref.watch(actsProvider);
  }

  Future<void> pause(int memId) => v(
        () async {
          final now = DateAndTime.now();

          final updatedEntities = await _actsClient.pause(memId, now);

          // ignore: avoid_manual_providers_as_generated_provider_dependency
          ref.read(actsProvider.notifier).upsertAll(
                updatedEntities,
                (c, u) => c.id == u.id,
              );
        },
        {
          'memId': memId,
        },
      );

  Future<void> close(int memId) => v(
        () async {
          final closed = await _actsClient.close(memId);

          if (closed != null) {
            final latestActs = await _actService.fetchLatestByMemIds([memId]);
            // ignore: avoid_manual_providers_as_generated_provider_dependency
            ref.read(actsProvider.notifier).upsertAll(
                  latestActs,
                  (c, u) => c.id == u.id,
                  removeWhere: (e) => e.id == closed.id,
                );
          }
        },
        {'memId': memId},
      );
}

final actListProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<SavedActEntity>, List<SavedActEntity>, int?>(
  (ref, memId) => v(
    () {
      if (ref.read(isUpdating(memId))) {
        ref.watch(isUpdating(memId));
      } else {
        Future.microtask(() async {
          ref.read(isLoading(memId).notifier).updatedBy(true);

          final latest = await _actsClient.fetch(memId, 1);
          final c = ref.read(currentPage(memId));

          ListWithTotalPage<SavedActEntity>? byPage;
          if (c != 1) {
            byPage = await _actsClient.fetch(memId, c);
          }

          ref.read(isLoading(memId).notifier).updatedBy(false);
          ref.read(isUpdating(memId).notifier).updatedBy(true);
          ref.read(maxPage(memId).notifier).updatedBy(latest.totalPage);
          ref.read(actsProvider.notifier).upsertAll(
            [
              ...latest.list,
              if (byPage != null) ...byPage.list,
            ],
            (current, updating) => current.id == updating.id,
          );
        });
      }

      return ListValueStateNotifier(
        ref
            .watch(actsProvider)
            .where((act) => memId == null || act.value.memId == memId)
            .where(
              (e) => e.value.period != null,
            )
            .sorted((a, b) => b.value.period!.compareTo(a.value.period!)),
      );
    },
    {
      "memId": memId,
    },
  ),
);

@riverpod
Map<int, Act?>? latestActsByMemV2(Ref ref) => v(
      () => ref.watch(
        actsV2Provider.select(
          (value) => value.value
              ?.groupListsBy(
                (element) => element.value.memId,
              )
              .map(
                (key, value) => MapEntry(
                  key,
                  value
                      .sorted(
                        (a, b) => b.createdAt.compareTo(a.createdAt),
                      )
                      .firstOrNull
                      ?.value,
                ),
              ),
        ),
      ),
    );

@riverpod
Act? latestActByMem(Ref ref, int? memId) => v(
      () => memId == null
          ? null
          : ref.watch(
              latestActsByMemV2Provider.select(
                (value) => value?[memId],
              ),
            ),
      {
        'memId': memId,
      },
    );
