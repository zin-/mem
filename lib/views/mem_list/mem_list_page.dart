import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';

import 'package:mem/views/colors.dart';
import 'package:mem/views/atoms/async_value_view.dart';
import 'package:mem/views/constants.dart';
import 'package:mem/views/mem_detail/mem_detail_page.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mem_list/mem_list_filter.dart';
import 'package:mem/views/mem_list/mem_list_page_states.dart';
import 'package:mem/views/mem_name.dart';

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
                      final memMap = mem.toMap();
                      return ListTile(
                        title: MemNameText(memMap['name'] ?? '', memMap['id']),
                        onTap: () =>
                            showMemDetailPage(context, ref, mem.toMap()['id']),
                      );
                    },
                  ),
                ),
                bottomNavigationBar: BottomAppBar(
                  shape: const CircularNotchedRectangle(),
                  child: IconTheme(
                    data: const IconThemeData(color: iconOnPrimaryColor),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            builder: (context) => const MemListFilter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  child: const Icon(Icons.add),
                  onPressed: () => showMemDetailPage(context, ref, null),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
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
            .push<Mem?>(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MemDetailPage(memId),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
                transitionDuration: defaultTransitionDuration,
                reverseTransitionDuration: defaultTransitionDuration,
              ),
            )
            .then(
              (result) => v(
                {'result': result},
                () {
                  if (result != null) {
                    ref.read(memListProvider.notifier).add(
                          result,
                          (item) => item.id == result.id,
                        );
                  }
                  if (memId == null) {
                    ref.read(memMapProvider(memId).notifier).updatedBy({});
                  }
                },
              ),
            );
      },
    );
