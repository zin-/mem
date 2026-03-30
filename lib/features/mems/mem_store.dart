import 'package:collection/collection.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';

// BEとの連携は全てStoreを通じて行う
// - TODO FEで保持される情報はどうする？
//   - ユーザーだけの設定とか
//   ここで混ぜる　べき？もう一層あるべき？
// - FIXME MemsStoreの方が適切か？
class MemStore {
  final MemRepository _memRepository;

  final List<SavedMemEntityV1> _memStock = [];

  Future<List<SavedMemEntityV1>> serve({bool? archived, bool? done}) => v(
        () async {
          final mems = await _memRepository
              .shipV2(
                archived: archived,
                done: done,
                loadChildren: MemRepository.loadLatestActChild,
              )
              .then((v) =>
                  v.map((e) => SavedMemEntityV1.fromEntityV2(e)).toList());

          _memStock.addAll(mems);

          return mems;
        },
        {
          'archived': archived,
          'done': done,
        },
      );

  Future<Mem> serveOneBy(int? memId) async => v(
        () async {
          final stock =
              _memStock.singleWhereOrNull((e) => e.id == memId)?.value;
          if (stock != null) {
            return stock;
          }

          if (memId != null) {
            final saved = await _memRepository.shipById(
              memId,
              loadChildren: MemRepository.loadLatestActChild,
            );

            _memStock.add(SavedMemEntityV1.fromEntityV2(saved));
            return saved.toDomain();
          }

          return Mem(null, "", null, null);
        },
        {
          'memId': memId,
        },
      );

  MemStore._(this._memRepository);

  static MemStore? _instance;

  factory MemStore() => _instance ??= MemStore._(MemRepository());
}
