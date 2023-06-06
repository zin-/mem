import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/component/view/mem_list/states.dart';
import 'package:mem/logger/log_service_v2.dart';

final fetchActiveActs = Provider(
  (ref) => d(
    () async {
      final fetched = await ActRepository().shipActive();
      ref.read(activeActsProvider.notifier).upsertAll(
            fetched,
            (tmp, item) => tmp.id == item.id,
          );
    },
  ),
);
