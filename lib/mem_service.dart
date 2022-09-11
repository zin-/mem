import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_detail_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

class MemService {
  Future<MemEntity> create(Map<String, dynamic> memMap) => t(
        {'memMap': memMap},
        () async {
          final memDetails = {
            MemDetailType.memo: memMap.remove(MemDetailType.memo.name),
          };

          final receivedMem = await MemRepository().receive(memMap);
          memDetails.forEach((key, value) async {
            if (value != null) {
              await MemDetailRepository().receive({
                memIdColumnName: receivedMem.id,
                memDetailTypeColumnName: key.toString(),
                memDetailValueColumnName: value,
              });
            }
          });

          return receivedMem;
        },
      );
}
