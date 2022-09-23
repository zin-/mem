import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mem_list/mem_list_page.dart';
import 'package:mem/views/mem_name.dart';

class MemListItemView extends StatelessWidget {
  final int _memId;

  const MemListItemView(this._memId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'_memId': _memId},
        () => Consumer(
          builder: (context, ref, child) {
            final mem = ref.watch(memProvider(_memId));

            if (mem == null) {
              ref.watch(fetchMemById(_memId));
              return const CircularProgressIndicator();
            } else {
              return ListTile(
                title: MemNameText(mem.name, mem.id),
                onTap: () => showMemDetailPage(
                  context,
                  ref,
                  mem.id,
                ),
              );
            }
          },
        ),
      );
}
