import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/features/settings/page.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference.dart';
import 'package:mem/features/settings/preference/repository.dart';
import 'package:mockito/mockito.dart';
import '../../helpers.mocks.dart' show MockPreferenceRepository;

void main() {
  final mockedPreferenceRepository = MockPreferenceRepository();

  PreferenceRepository(mock: mockedPreferenceRepository);

  setUp(() {
    reset(mockedPreferenceRepository);

    when(mockedPreferenceRepository.shipByKey(startOfDayKey))
        .thenAnswer((_) async => PreferenceEntity(
              startOfDayKey,
              defaultStartOfDay,
            ));
    when(mockedPreferenceRepository.shipByKey(notifyAfterInactivity))
        .thenAnswer((_) async => PreferenceEntity(
              notifyAfterInactivity,
              defaultNotifyAfterInactivity,
            ));

    when(mockedPreferenceRepository.receive(any)).thenAnswer((_) async => true);
  });

  group('Backup test', () {
    testWidgets('should display', (tester) async {
      final l10n = buildL10n();

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(home: SettingsPage()),
      ));
      await tester.pumpAndSettle();

      expect(find.text(l10n.backupLabel), findsOneWidget);
      expect(find.text(l10n.createBackupLabel), findsOneWidget);
      expect(find.text(l10n.restoreBackupLabel), findsOneWidget);
    });
  });
}
