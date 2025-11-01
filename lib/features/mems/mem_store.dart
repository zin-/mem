import 'package:collection/collection.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';

// FIXME MemsStoreの方が適切か？
class MemStore {
  final MemRepository _memRepository;

  final List<SavedMemEntity> _memStock = [];

  Future<List<SavedMemEntity>> serve({bool? archived, bool? done}) => v(
        () async {
          final mems = await _memRepository.ship(
            archived: archived,
            done: done,
          );

          _memStock.addAll(mems);

          return mems;
        },
        {
          'archived': archived,
          'done': done,
        },
      );

  Future<Mem> serveOneBy(int? memId) async => v(
        () async =>
            _memStock.singleWhereOrNull((e) => e.id == memId)?.value ??
            await _memRepository.ship(id: memId).then(
              (v) {
                final savedMem = v.singleOrNull;
                if (savedMem != null) {
                  _memStock.add(savedMem);
                  return savedMem.value;
                }
                return Mem(null, "", null, null);
              },
            ),
        {
          'memId': memId,
        },
      );

  MemStore._(this._memRepository);

  static MemStore? _instance;

  factory MemStore() => _instance ??= MemStore._(MemRepository());
}
