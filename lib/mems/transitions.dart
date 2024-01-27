import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/actions.dart';
import 'package:mem/mems/detail/page.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/values/durations.dart';

// FIXME 使い勝手が悪いので改修する
void showMemDetailPage(BuildContext context, WidgetRef? ref, int? memId) => v(
      () {
        Navigator.of(context)
            .push<bool?>(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MemDetailPage(memId),
            transitionsBuilder: _showMemDetailTransitionBuilder,
            transitionDuration: defaultTransitionDuration,
            reverseTransitionDuration: defaultTransitionDuration,
          ),
        )
            .then(
          (result) {
            if (ref != null) {
              handleRemoved(context, ref, memId, result);
            }
          },
        );
      },
      [context, ref, memId],
    );

Widget _showMemDetailTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );

const keyUndo = Key("undo");

void handleRemoved(
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
                  key: keyUndo,
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
