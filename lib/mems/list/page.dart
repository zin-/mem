import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/colors.dart';
import 'package:mem/gui/constants.dart';
import 'package:mem/mems/mem_detail_page.dart';
import 'package:mem/mems/mem_detail_states.dart';
import 'package:mem/mems/mem_list_actions.dart';
import 'package:mem/mems/mem_list_filter.dart';
import 'package:mem/mems/mem_list_view.dart';
import 'package:mem/mems/show_new_mem_fab.dart';
import 'package:mem/mems/mems_action.dart';

import '../mem_list_page_states.dart';

class MemListPage extends StatelessWidget {
  final _scrollController = ScrollController();

  MemListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => Consumer(
          builder: (context, ref, child) {
            ref.read(
              initialize((memId) => showMemDetailPage(context, ref, memId)),
            );

            return Consumer(
              builder: (context, ref, child) => v(
                {},
                () {
                  ref.watch(fetchMemList);

                  return Scaffold(
                    body: MemListView(
                      L10n().memListPageTitle(),
                      scrollController: _scrollController,
                      appBarActions: [
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
                      onItemTapped: (memId) => showMemDetailPage(
                        context,
                        ref,
                        memId,
                      ),
                    ),
                    floatingActionButton: ShowNewMemFab(_scrollController),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerFloat,
                  );
                },
              ),
            );
          },
        ),
      );
}

// FIXME too long
void showMemDetailPage(BuildContext context, WidgetRef ref, int? memId) => v(
      {'context': context, 'memId': memId},
      () => Navigator.of(context)
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
                if (memId == null) {
                  ref.read(memProvider(memId).notifier).updatedBy(null);
                  ref.read(memItemsProvider(memId).notifier).updatedBy(null);
                  if (result != null) {
                    ref.read(memListProvider.notifier).add(result);
                  }
                } else {
                  if (result == null) {
                    ref.read(memListProvider.notifier).removeWhere(
                          (item) => item.id == memId,
                        );
                    final mem = ref.read(memProvider(memId));
                    if (mem != null) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            L10n().removeMemSuccessMessage(mem.name),
                          ),
                          duration: defaultDismissDuration,
                          dismissDirection: DismissDirection.horizontal,
                          action: SnackBarAction(
                            label: L10n().undoAction(),
                            onPressed: () => v(
                              {},
                              () {
                                ref.read(undoRemoveMem(memId));
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      L10n().saveMemSuccessMessage(mem.name),
                                    ),
                                    duration: infiniteDismissDuration,
                                    dismissDirection:
                                        DismissDirection.horizontal,
                                  ),
                                );
                                ref.read(memListProvider.notifier).add(mem);
                              },
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ),
    );