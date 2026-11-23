import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act, Mem;
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mems/home/overdue_mems.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/framework/singleton.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MidnightPreference extends Preference<TimeOfDay> {
  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 0, minute: 0);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.memory();
    await Migrator(db).createAll();
    DriftDatabaseAccessor.reset();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    Singleton.reset<MemRepository>();
  });

  tearDown(() async {
    await db.close();
    DriftDatabaseAccessor.reset();
    Singleton.reset<MemRepository>();
  });

  // 作成日時の基準。通知時刻とは無関係
  final createdAt = DateTime(2024, 6, 1);

  Future<int> insertMem(
    String name, {
    DateTime? notifyAt,
    DateTime? doneAt,
    DateTime? archivedAt,
  }) async {
    return (await db.into(db.mems).insertReturning(
              MemsCompanion.insert(
                name: name,
                createdAt: createdAt,
                notifyOn: Value(notifyAt),
                notifyAt: Value(notifyAt),
                doneAt: Value(doneAt),
                archivedAt: Value(archivedAt),
              ),
            ))
        .id;
  }

  Future<void> insertItem(int memId) => db.into(db.memItems).insert(
        MemItemsCompanion.insert(
          memId: memId,
          type: 'memo',
          value: 'only on non-candidate',
          createdAt: createdAt,
        ),
      );

  Future<void> insertRepeat(int memId, {required int hour}) =>
      MemRepository().receiveRepeatedNotification(
        MemNotification.by(
          memId,
          MemNotificationType.repeat,
          hour * Duration.secondsPerHour,
          'repeat',
        ),
      );

  Future<void> insertTarget({
    required int memId,
    required int value,
    required int secondsAfterLastAct,
  }) =>
      db.into(db.targets).insert(
            TargetsCompanion.insert(
              type: TargetType.equalTo.name,
              unit: TargetUnit.count.name,
              value: value,
              period: Period.aDay.name,
              memId: memId,
              createdAt: createdAt,
              secondsAfterLastAct: Value(secondsAfterLastAct),
            ),
          );

  Future<void> insertFinishedAct({
    required int memId,
    required DateTime start,
  }) =>
      db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: createdAt,
              start: Value(start),
              end: Value(start.add(const Duration(minutes: 30))),
              actKind: const Value('finished'),
            ),
          );

  ProviderContainer container() {
    final result = ProviderContainer(
      overrides: [
        // overdueMems は一覧 load に頼らず候補を DB から取る想定
        loadMemListProvider.overrideWith((ref) async {}),
        preferenceProvider(startOfDayKey)
            .overrideWith(() => _MidnightPreference()),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  Future<List<int>> overdueIds(ProviderContainer scope) async {
    // autoDispose の読み取り中に dispose されないよう購読を残す
    final sub = scope.listen(overdueMemsProvider, (_, __) {});
    addTearDown(sub.close);
    final overdue = await scope.read(overdueMemsProvider.future);
    return overdue.map((mem) => mem.id).toList();
  }

  test('returns mems whose notifyAt is before now in ascending order',
      () async {
    final now = DateTime.now();
    final earliest = now.subtract(const Duration(hours: 4));
    final middle = now.subtract(const Duration(hours: 2));
    final latest = now.subtract(const Duration(hours: 1));

    final middleId = await insertMem('middle', notifyAt: middle);
    final latestId = await insertMem('latest', notifyAt: latest);
    final earliestId = await insertMem('earliest', notifyAt: earliest);

    expect(
      await overdueIds(container()),
      [earliestId, middleId, latestId],
    );
  });

  test(
    'omits a future-only period, a plain mem, done, and archived',
    () async {
      final now = DateTime.now();
      final past = now.subtract(const Duration(hours: 1));
      final future = now.add(const Duration(days: 1));

      final overdueId = await insertMem('overdue', notifyAt: past);
      await insertMem('future period', notifyAt: future);
      await insertMem('plain');
      await insertMem('done', notifyAt: past, doneAt: createdAt);
      await insertMem('archived', notifyAt: past, archivedAt: createdAt);

      expect(await overdueIds(container()), [overdueId]);
    },
  );

  test(
    'omits a daily count mem once the period count is reached',
    () async {
      final now = DateTime.now();
      final past = now.subtract(const Duration(hours: 1));
      // 時間。前回終了からこの秒後が notifyAt になる
      const intervalSeconds = 2 * 60 * 60;
      // 回。この回数に達すると当日の間隔通知は出さない
      const dailyTarget = 2;
      // 時。繰り返し通知の固定時刻。達したあとは翌日のこの時刻へ進む
      const repeatHour = 9;

      final overdueId = await insertMem('overdue', notifyAt: past);
      final reachedId = await insertMem('reached');
      await insertRepeat(reachedId, hour: repeatHour);
      await insertTarget(
        memId: reachedId,
        value: dailyTarget,
        secondsAfterLastAct: intervalSeconds,
      );

      final firstStart = DateTime(now.year, now.month, now.day, 8);
      final secondStart = firstStart.add(const Duration(hours: 1));
      await insertFinishedAct(memId: reachedId, start: firstStart);
      await insertFinishedAct(memId: reachedId, start: secondStart);

      // 回数を読んだ結果、達した mem は翌日へ進み Overdue に残らない
      expect(await overdueIds(container()), [overdueId]);
    },
  );

  test(
    'keeps the same overdue result when only a non-candidate has items',
    () async {
      final now = DateTime.now();
      final past = now.subtract(const Duration(hours: 1));

      final overdueId = await insertMem('overdue', notifyAt: past);
      final plainId = await insertMem('plain');
      await insertItem(plainId);

      expect(await overdueIds(container()), [overdueId]);
    },
  );
}
