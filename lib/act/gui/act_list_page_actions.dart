import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/act/domain/act.dart';
import 'package:mem/act/domain/date_and_time_period.dart';
import 'package:mem/logger/api.dart';

final fetchActList = FutureProvider<List<Act>>(
  (ref) => v(
    {},
    () => List.generate(
      20,
      (index) => Act(
        DateAndTimePeriod.startNow(),
      ),
    ),
  ),
);
