import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/colors.dart';
import 'package:mem/gui/constants.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/actions.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/list/actions.dart';
import 'package:mem/mems/detail/page.dart';
import 'package:mem/mems/mem_list_filter.dart';
import 'package:mem/component/view/mem_list/view.dart';
import 'package:mem/mems/mems_action.dart';

import 'show_new_mem_fab.dart';

class MemListPage extends ConsumerWidget {
  const MemListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () {
          ref.read(
            initialize((memId) => showMemDetailPage(context, ref, memId)),
          );
          ref.read(fetchActiveActs);

          return _MemListPageComponent(
            (memId) => showMemDetailPage(
              context,
              ref,
              memId,
            ),
          );
        },
      );
}

class _MemListPageComponent extends StatelessWidget {
  final _scrollController = ScrollController();
  final void Function(MemId memId)? _onItemTapped;

  _MemListPageComponent(this._onItemTapped);

  @override
  Widget build(BuildContext context) {
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
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: ShowNewMemFab(_scrollController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// FIXME too long
void showMemDetailPage(BuildContext context, WidgetRef ref, int? memId) => v(
      () => Navigator.of(context)
          .push<bool?>(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MemDetailPageV2(memId),
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
              () {
                if (memId != null && result == true) {
                  final removed = ref.read(removedMemProvider(memId));

                  if (removed != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          L10n().removeMemSuccessMessage(removed.name),
                        ),
                        duration: infiniteDismissDuration,
                        dismissDirection: DismissDirection.horizontal,
                        action: SnackBarAction(
                          label: L10n().undoAction(),
                          onPressed: () {
                            ref.read(undoRemoveMem(memId));

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  L10n().saveMemSuccessMessage(removed.name),
                                ),
                                duration: infiniteDismissDuration,
                                dismissDirection: DismissDirection.horizontal,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              {'result': result},
            ),
          ),
      {'context': context, 'memId': memId},
    );
