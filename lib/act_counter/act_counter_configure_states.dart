import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';

final selectMem = Provider.family<void, MemId>((ref, memId) => v(
      {'memId': memId},
      () {},
    ));
