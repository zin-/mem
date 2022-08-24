import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/colors.dart';
import 'package:mem/views/constants.dart';
import 'package:mem/views/mem_detail/mem_detail_page.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mem_list/mem_list_filter.dart';
import 'package:mem/views/mem_list/mem_list_page_states.dart';
import 'package:mem/views/mem_name.dart';
import 'package:mem/views/show_new_mem_fab.dart';

class MemListPage extends StatelessWidget {
  final _scrollController = ScrollController();

  MemListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => Consumer(
          builder: (context, ref, child) => v(
            {},
            () {
              // final onScrollReversed = ref.watch(onScrollReversedProvider);

              // scrollController.addListener(() {
              //   final onScrollReversedProviderNotifier =
              //       ref.read(onScrollReversedProvider.notifier);
              //   if (scrollController.position.userScrollDirection ==
              //           ScrollDirection.forward &&
              //       onScrollReversed) {
              //     // onScrollReversedProviderNotifier.updatedBy(false);
              //     dev(1);
              //   } else if (scrollController.position.userScrollDirection ==
              //           ScrollDirection.reverse &&
              //       !onScrollReversed) {
              //     onScrollReversedProviderNotifier.updatedBy(true);
              //     dev(2);
              //   }
              // });

              final memListAsyncValue = ref.read(fetchMemList);
              final memList = ref.watch(memListProvider);

              return Scaffold(
                body: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      title: Text(L10n().memListPageTitle()),
                      floating: true,
                      actions: [
                        IconTheme(
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
                      ],
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final mem = memList[index];
                          return ListTile(
                            title: MemNameText(mem.name, mem.id),
                            onTap: () => showMemDetailPage(
                              context,
                              ref,
                              mem.id,
                            ),
                          );
                        },
                        childCount: memList.length,
                      ),
                    ),
                  ],
                ),
                floatingActionButton: ShowNewMemFab(_scrollController),
                // floatingActionButton: _buildFab(context, ref),
                // floatingActionButton: FloatingActionButton(
                //   onPressed: () => showMemDetailPage(context, ref, null),
                //   child: const Icon(Icons.add),
                // ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerFloat,
              );
              return Scaffold(
                appBar: AppBar(
                  title: Text(L10n().memListPageTitle()),
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

  Widget _buildFab(BuildContext context, WidgetRef ref) {
    const duration = Duration(milliseconds: 750);
    final showFab = !ref.watch(onScrollReversedProvider);
    return AnimatedSlide(
      offset: showFab ? Offset.zero : Offset(0, 2),
      duration: duration,
      child: AnimatedOpacity(
        opacity: showFab ? 1 : 0,
        duration: duration,
        child: FloatingActionButton(
          onPressed: () => showMemDetailPage(context, ref, null),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
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
                  if (result == null) {
                    if (memId != null) {
                      ref.read(memListProvider.notifier).remove(
                            (item) => item.id == memId,
                          );
                    }
                  } else {
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
