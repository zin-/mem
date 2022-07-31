import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_repository.dart';

final fetchAllMem = FutureProvider<List<Mem>>(
  (ref) => v(
    {},
    () async {
      final mems = MemRepository().shipAll();
      return mems;
    },
    debug: true,
  ),
);
