import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/values/durations.dart';

import 'actions.dart';
import 'detail/page.dart';
import 'states.dart';

// FIXME 使い勝手が悪いので改修する
void showMemDetailPage(BuildContext context, WidgetRef? ref, int? memId) => v(
      () {
        final l10n = buildL10n(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        Navigator.of(context)
            .push<bool?>(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MemDetailPage(memId),
            transitionsBuilder: detailTransitionsBuilder,
            transitionDuration: defaultTransitionDuration,
            reverseTransitionDuration: defaultTransitionDuration,
          ),
        )
            .then(
          (result) {
            if (ref != null) {
              handleRemoved(l10n, scaffoldMessenger, ref, memId, result);
            }
          },
        );
      },
      [context, ref, memId],
    );

Widget detailTransitionsBuilder(
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
  AppLocalizations l10n,
  ScaffoldMessengerState scaffoldMessengerState,
  WidgetRef ref,
  int? memId,
  bool? result,
) =>
    v(
      () {
        if (memId != null && result == true) {
          final removed = ref.read(removedMemProvider(memId));

          if (removed != null) {
            scaffoldMessengerState.showSnackBar(
              SnackBar(
                content: Text(
                  l10n.removeMemSuccessMessage(removed.value.name),
                ),
                duration: infiniteDismissDuration,
                dismissDirection: DismissDirection.horizontal,
                action: SnackBarAction(
                  key: keyUndo,
                  label: l10n.undoAction,
                  onPressed: () {
                    ref.read(undoRemoveMem(memId));

                    scaffoldMessengerState.showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.undoMemSuccessMessage(removed.value.name),
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
      {
        'l10n': l10n,
        'scaffoldMessengerState': scaffoldMessengerState,
        'ref': ref,
        'memId': memId,
        'result': result,
      },
    );
