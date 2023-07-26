import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/view.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/actions.dart';
import 'package:mem/mems/list/actions.dart';
import 'package:mem/mems/detail/page.dart';
import 'package:mem/components/mem/list/filter.dart';
import 'package:mem/mems/mems_action.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/durations.dart';

import 'show_new_mem_fab.dart';

class MemListPage extends ConsumerWidget {
  const MemListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () {
          // TODO 消す
          //  contextが不要になるはずなので、削除する
          ref.read(
            initializeNotification(
// ISSUE #225
// coverage:ignore-start
              (memId) => showMemDetailPage(context, ref, memId),
// coverage:ignore-end
            ),
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
    final l10n = buildL10n(context);

    return Scaffold(
      body: MemListView(
        l10n.memListPageTitle,
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

// TODO 通知から呼び出すのをこれじゃなくする
//  直接run(MemDetailPage())する
// FIXME too long
void showMemDetailPage(BuildContext context, WidgetRef ref, int? memId) => v(
      () {
        final l10n = buildL10n(context);

        Navigator.of(context)
            .push<bool?>(
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
                () {
                  if (memId != null && result == true) {
                    final removed = ref.read(removedMemProvider(memId));

                    if (removed != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.removeMemSuccessMessage(removed.name),
                          ),
                          duration: infiniteDismissDuration,
                          dismissDirection: DismissDirection.horizontal,
                          action: SnackBarAction(
                            label: l10n.undoAction,
                            onPressed: () {
                              ref.read(undoRemoveMem(memId));

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.undoMemSuccessMessage(removed.name),
                                  ),
                                  duration: defaultDismissDuration,
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
            );
      },
      {'context': context, 'memId': memId},
    );
