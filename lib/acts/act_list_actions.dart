import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

import 'states.dart';

final loadActList = FutureProvider.autoDispose.family<List<Act>, int>(
  (ref, memId) => v(
    () async {
      final acts = await ActRepository().shipByMemId(memId);

      ref.watch(actsProvider.notifier).upsertAll(
            acts,
            (tmp, item) => tmp.id == item.id,
          );

      return acts;
    },
  ),
);
