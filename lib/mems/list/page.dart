import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/actions.dart';
import 'package:mem/mems/list/actions.dart';
import 'package:mem/mems/detail/page.dart';
import 'package:mem/components/mem/list/filter.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/durations.dart';

import 'show_new_mem_fab.dart';

class MemListPage extends ConsumerWidget {
  const MemListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () {
          ref.read(fetchActiveActs);

          return _MemListPageComponent();
        },
      );
}

class _MemListPageComponent extends StatelessWidget {
  final _scrollController = ScrollController();

  _MemListPageComponent();

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
      ),
      floatingActionButton: ShowNewMemFab(_scrollController),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

void showMemDetailPage(BuildContext context, WidgetRef ref, int? memId) => v(
      () => Navigator.of(context)
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
            (result) => _handleRemoved(context, ref, memId, result),
          ),
      [context, ref, memId],
    );

void _handleRemoved(
  BuildContext context,
  WidgetRef ref,
  int? memId,
  bool? result,
) =>
    v(
      () {
        if (memId != null && result == true) {
          final removed = ref.read(removedMemProvider(memId));

          if (removed != null) {
            final l10n = buildL10n(context);

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
      [context, ref, memId, result],
    );
