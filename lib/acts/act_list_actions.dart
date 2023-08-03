import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_list_states.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

final loadActList = FutureProvider.autoDispose.family<List<Act>, int>(
  (ref, memId) => v(
    () async {
      final acts = await ActRepository().shipByMemId(memId);

      ref.watch(actListProvider(memId).notifier).updatedBy(acts);

      return acts;
    },
  ),
);
