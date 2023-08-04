import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/logger/log_service.dart';

final fetchActiveActs = Provider(
  (ref) => v(
    () => ActRepository().shipActive().then(
          (activeActs) => ref.read(actsProvider.notifier).updatedBy(activeActs),
        ),
  ),
);
