import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act, Mem;
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/mems/home/habitual_mems.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/singleton.dart';

import '../../../entity_factories.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _initial;

  _FakeMemEntities(this._initial);

  @override
  Iterable<MemEntity> build() => _initial;
}

void main() {
  // 日。初期値 28 より短く、この日数より前に始まった Act は取得しない
  const lookbackDays = 1;
  // 時間。今の前後この時間に重なる Act だけを対象にする
  const timeRadiusHours = 1;

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Migrator(db).createAll();
    DriftDatabaseAccessor.reset();
    Singleton.reset<ActQueryService>();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
  });

  tearDown(() async {
    await db.close();
    DriftDatabaseAccessor.reset();
    Singleton.reset<ActQueryService>();
  });

  test('omits an act that started before the lookback', () async {
    final now = DateTime.now();
    final createdAt = DateTime(2026, 6, 1);

    Future<int> insertMem(String name) async =>
        (await db.into(db.mems).insertReturning(
                  MemsCompanion.insert(name: name, createdAt: createdAt),
                ))
            .id;

    Future<void> finished(int memId, DateTime start) => db.into(db.acts).insert(
          ActsCompanion.insert(
            memId: memId,
            createdAt: createdAt,
            start: Value(start),
            end: Value(start.add(const Duration(minutes: 30))),
            actKind: const Value('finished'),
          ),
        );

    final recentId = await insertMem('recent');
    final olderId = await insertMem('older');
    // 今の窓に重なる。参照期間の内側なので一覧に残る
    await finished(recentId, now.subtract(const Duration(minutes: 20)));
    // 同じ時刻でも参照期間より前。取得の since より古いので一覧から外れる
    await finished(olderId, now.subtract(const Duration(days: 2)));

    MemEntity mem(int id, String name) => savedMem(
          id: id,
          name: name,
          createdAt: createdAt,
          updatedAt: createdAt,
        );

    final container = ProviderContainer(
      overrides: [
        loadMemListProvider.overrideWith((ref) async {}),
        memEntitiesProvider.overrideWith(
          () => _FakeMemEntities([
            mem(recentId, 'recent'),
            mem(olderId, 'older'),
          ]),
        ),
        preferenceProvider(habitualMemsTimeRadiusKey)
            .overrideWithValue(timeRadiusHours),
        preferenceProvider(habitualMemsLookbackKey)
            .overrideWithValue(lookbackDays),
      ],
    );
    addTearDown(container.dispose);

    final habitual = await container.read(habitualMemsProvider.future);

    expect(
      habitual.map((item) => item.mem.id).toList(),
      [recentId],
    );
  });
}
