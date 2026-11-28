import 'package:collection/collection.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/features/mems/list/list_period_count.dart';
import 'package:mem/features/mems/list/period_counts.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/widgets/infinite_scroll.dart';
import 'package:mem/shared/entities_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'states.g.dart';

@Riverpod(keepAlive: true)
class ActEntities extends _$ActEntities
    with EntitiesStateMixinV1<SavedActEntityV1, int> {
  final ActQueryService _actQueryService = ActQueryService();

  @override
  Iterable<SavedActEntityV1> build() => [];

  Future<Iterable<SavedActEntityV1>> fetch(
    int memId,
    Period period, {
    int offset = 0,
  }) =>
      v(
        () async {
          final actEntities = await _actQueryService
              .fetchByMemIdAndPeriod(
                memId,
                period.toPeriod(
                  DateAndTime.now(),
                  ref.watch(preferenceProvider(startOfDayKey)),
                  offset: offset,
                ),
              )
              .then(
                (v) => v.map((e) => SavedActEntityV1.fromEntityV2(e)).toList(),
              );

          upsert(actEntities);

          return actEntities;
        },
        {
          'memId': memId,
          'period': period,
          'offset': offset,
        },
      );

  Future<void> reloadShown(int? memId) => v(
        () async {
          ref
              .read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                isLoading(memId).notifier,
              )
              .updatedBy(true);

          final latest = await ActsClient().fetch(memId, 1);
          final c = ref.read(
            // ignore: avoid_manual_providers_as_generated_provider_dependency
            currentPage(memId),
          );

          ListWithTotalPage<SavedActEntityV1>? byPage;
          if (c != 1) {
            byPage = await ActsClient().fetch(memId, c);
          }

          ref
              .read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                isLoading(memId).notifier,
              )
              .updatedBy(false);
          ref
              .read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                isUpdating(memId).notifier,
              )
              .updatedBy(true);
          ref
              .read(
                // ignore: avoid_manual_providers_as_generated_provider_dependency
                maxPage(memId).notifier,
              )
              .updatedBy(latest.totalPage);

          upsert([
            ...latest.list,
            if (byPage != null) ...byPage.list,
          ]);
        },
        {
          'memId': memId,
        },
      );

  Future<void> startActby(int memId) => v(
        () async {
          final now = DateAndTime.now();

          final startedAct = await ActsClient().start(memId, now);

          upsert([startedAct]);
          await ref
              .read(memEntitiesProvider.notifier)
              .refreshLatestActForMem(memId);
        },
        {
          'memId': memId,
        },
      );

  Future<void> resumeActBy(int memId) => v(
        () async {
          final now = DateAndTime.now();

          final resumedAct = await ActsClient().resume(memId, now);

          upsert([resumedAct]);
          await ref
              .read(memEntitiesProvider.notifier)
              .refreshLatestActForMem(memId);
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
          await ref
              .read(memEntitiesProvider.notifier)
              .refreshLatestActForMem(memId);
        },
        {
          'memId': memId,
        },
      );

  Future<void> unpauseByMemId(int memId) => v(
        () async {
          final unpausedActEntities = await ActsClient().unpause(memId);

          if (unpausedActEntities.isNotEmpty) {
            remove(unpausedActEntities.map((e) => e.id));
          }
          await ref
              .read(memEntitiesProvider.notifier)
              .refreshLatestActForMem(memId);
        },
        {'memId': memId},
      );

  Future<void> finishActby(int memId) => v(
        () async {
          final now = DateAndTime.now();

          final finishedAct = await ActsClient().finish(memId, now);

          upsert([finishedAct]);
          await ref
              .read(memEntitiesProvider.notifier)
              .refreshLatestActForMem(memId);
        },
        {
          'memId': memId,
        },
      );

  Future<void> skipActBy(int memId) => v(
        () async {
          final now = DateAndTime.now();

          final skippedAct = await ActsClient().skip(memId, now);

          upsert([skippedAct]);
          await ref
              .read(memEntitiesProvider.notifier)
              .refreshLatestActForMem(memId);
        },
        {
          'memId': memId,
        },
      );

  Future<void> edit(SavedActEntityV1 act) => v(
        () async {
          final editedAct = await ActsClient().edit(act);

          upsert([editedAct]);
          await ref
              .read(memEntitiesProvider.notifier)
              .refreshLatestActForMem(act.value.memId);
        },
        {
          'act': act,
        },
      );

  Future<Iterable<SavedActEntityV1>> removeAsync(Iterable<int> ids) => v(
        () async {
          final memIds = state
              .where((e) => ids.contains(e.id))
              .map((e) => e.value.memId)
              .whereType<int>()
              .toSet();
          await Future.wait(ids.map((id) => ActsClient().delete(id)));

          final removed = remove(ids);
          for (final memId in memIds) {
            await ref
                .read(memEntitiesProvider.notifier)
                .refreshLatestActForMem(memId);
          }
          return removed;
        },
        {'ids': ids},
      );
}

@Riverpod(keepAlive: true)
class ActCountsByMemIdByDate extends _$ActCountsByMemIdByDate {
  bool _loaded = false;

  @override
  Map<int, int> build(DateTime date) => v(
        () {
          final acts = ref.watch(actEntitiesProvider);
          final startOfDay = ref.watch(preferenceProvider(startOfDayKey));
          final startOfToday = date.atStartOfDay(startOfDay);
          final endOfToday = startOfToday.shiftCalendarDays(1);

          return acts
              .where(
            (act) =>
                act.value.period != null &&
                act.value.period!.start!.isAfter(startOfToday) &&
                act.value.period!.start!.isBefore(endOfToday),
          )
              .fold(
            <int, int>{},
            (map, act) => map
              ..putIfAbsent(
                act.value.memId,
                () => (map[act.value.memId] ?? 0) + 1,
              ),
          );
        },
        {'date': date},
      );

  Future<Map<int, int>> load() => v(
        () async {
          if (_loaded) return state;

          final now = DateTime.now();
          final startOfDay = ref.read(preferenceProvider(startOfDayKey));

          final mems = ref.read(memEntitiesProvider);
          if (mems.isEmpty) return <int, int>{};

          final periodCountByMemId = await ListPeriodWindows.of(
            mems: [
              for (final mem in mems)
                if (mem.target?.secondsAfterLastAct != null) mem,
            ],
            startOfDay: startOfDay,
            now: now,
          ).counts();
          // FIXME actsを更新する

          _loaded = true;
          state = periodCountByMemId;

          return periodCountByMemId;
        },
        {'date': date},
      );
}

@riverpod
Future<void> loadActList(Ref ref, int memId, Period period, int offset) => v(
      () async {
        await ref
            .watch(actEntitiesProvider.notifier)
            .fetch(memId, period, offset: offset);
      },
      {
        'memId': memId,
        'period': period,
        'offset': offset,
      },
    );

@riverpod
List<SavedActEntityV1> actList(Ref ref, int? memId) => v(
      () {
        if (ref.read(
            // ignore: avoid_manual_providers_as_generated_provider_dependency
            isUpdating(memId))) {
          ref.watch(
              // ignore: avoid_manual_providers_as_generated_provider_dependency
              isUpdating(memId));
        } else {
          Future.microtask(() async {
            await ref.read(actEntitiesProvider.notifier).reloadShown(memId);
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
