import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';

import 'act_list_view.dart';

class ActListPage extends ConsumerWidget {
  final MemId _memId;

  const ActListPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => t(
        {},
        () => Scaffold(
          body: ActListView(_memId),
        ),
      );
}
