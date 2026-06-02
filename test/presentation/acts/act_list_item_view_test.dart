import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/list/item/editing_act_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/acts/list/item/view.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';

void main() {
  group('ActListItemView', () {
    SavedActEntityV1 actEntity({
      ActKind? actKind,
      String? actKindRaw,
    }) {
      return SavedActEntityV1({
        'id': 1,
        'mems_id': 2,
        'start': DateTime(2024, 6, 1, 10),
        'start_is_all_day': false,
        'end': DateTime(2024, 6, 1, 11),
        'end_is_all_day': false,
        'paused_at': null,
        if (actKindRaw != null) 'act_kind': actKindRaw,
        if (actKind != null) 'act_kind': actKind.name,
        'createdAt': DateTime(2024, 6, 1),
        'updatedAt': DateTime(2024, 6, 1),
        'archivedAt': null,
      });
    }

    Widget wrap(Widget child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        );

    testWidgets('shows skipped label without mem name', (tester) async {
      await tester.pumpWidget(
        wrap(ActListItemView(actEntity(actKind: ActKind.skipped), null)),
      );
      await tester.pumpAndSettle();

      expect(find.text(buildL10n().actSkippedLabel), findsOneWidget);
    });

    testWidgets('shows mem name and skipped label', (tester) async {
      await tester.pumpWidget(
        wrap(ActListItemView(actEntity(actKind: ActKind.skipped), 'mem-a')),
      );
      await tester.pumpAndSettle();

      expect(find.text('mem-a'), findsOneWidget);
      expect(find.text(buildL10n().actSkippedLabel), findsOneWidget);
    });

    testWidgets('shows mem name only for finished act', (tester) async {
      await tester.pumpWidget(
        wrap(ActListItemView(actEntity(actKind: ActKind.finished), 'mem-b')),
      );
      await tester.pumpAndSettle();

      expect(find.text('mem-b'), findsOneWidget);
      expect(find.text(buildL10n().actSkippedLabel), findsNothing);
    });

    testWidgets('opens edit dialog on long press', (tester) async {
      final act = actEntity(actKind: ActKind.finished);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            actEntitiesProvider.overrideWith(
              () => _ActEntitiesWith([act]),
            ),
          ],
          child: wrap(ActListItemView(act, null)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(EditingActDialog), findsOneWidget);
    });
  });
}

class _ActEntitiesWith extends ActEntities {
  final List<SavedActEntityV1> _acts;

  _ActEntitiesWith(this._acts);

  @override
  Iterable<SavedActEntityV1> build() => _acts;
}
