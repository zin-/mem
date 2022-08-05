import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/async_value_view.dart';
import 'package:mem/views/mem_detail/mem_detail_page.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mem_list/mem_list_page_states.dart';

class MemListPage extends StatelessWidget {
  const MemListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => Consumer(
          builder: (context, ref, child) => v(
            {},
            () {
              final memListAsyncValue = ref.watch(fetchMemList);
              final memList = ref.watch(memListProvider);

              return Scaffold(
                appBar: AppBar(
                  title: const Text('List'),
                ),
                body: AsyncValueView(
                  memListAsyncValue,
                  (List<Mem> _) => ListView.builder(
                    itemCount: memList.length,
                    itemBuilder: (context, index) {
                      final mem = memList[index];
                      // dev(ref.watch(memMapProvider(mem.id)));
                      return ListTile(
                        title: Text(mem.toMap()['name'] ?? ''),
                        onTap: () =>
                            showMemDetailPage(context, ref, mem.toMap()['id']),
                      );
                    },
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  child: const Icon(Icons.add),
                  onPressed: () => showMemDetailPage(context, ref, null),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerFloat,
              );
            },
          ),
        ),
      );
}

void showMemDetailPage(BuildContext context, WidgetRef ref, int? memId) => v(
      {'context': context, 'memId': memId},
      () {
        Navigator.of(context)
            .push<Mem?>(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MemDetailPage(memId),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) => child))
            .then((result) {
          if (result != null) {
            ref.read(memListProvider.notifier).updateWhere(
                  result,
                  (item) => item.id == result.id,
                );
          }
          if (memId == null) {
            ref.read(memMapProvider(memId).notifier).updatedBy({});
          }
        });
      },
    );
