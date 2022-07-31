import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';

final fetchAllMem = FutureProvider<List<Mem>>(
  (ref) => v(
    {},
    () async {
      final mems = await MemRepository().shipAll();
      mems.map((mem) =>
          ref.read(memMapProvider(mem.id).notifier).updatedBy(mem.toMap()));
      return mems;
    },
  ),
);
