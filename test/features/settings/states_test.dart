import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference.dart';
import 'package:mem/features/settings/preference/repository.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mockito/mockito.dart';

import '../../helpers.mocks.dart';

void main() {
  final mockedPreferenceRepository = MockPreferenceRepository();

  PreferenceRepository(mock: mockedPreferenceRepository);

  setUp(() {
    reset(mockedPreferenceRepository);
  });

  group('preferenceProvider', () {
    test('loads persisted start of day after async read', () async {
      const persisted = TimeOfDay(hour: 6, minute: 30);

      when(mockedPreferenceRepository.shipByKey(startOfDayKey))
          .thenAnswer((_) async => PreferenceEntity(startOfDayKey, persisted));
      when(mockedPreferenceRepository.shipByKey(notifyAfterInactivity))
          .thenAnswer((_) async => PreferenceEntity(
                notifyAfterInactivity,
                defaultNotifyAfterInactivity,
              ));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(preferenceProvider(startOfDayKey)),
        defaultStartOfDay,
      );

      await Future<void>.delayed(Duration.zero);

      expect(container.read(preferenceProvider(startOfDayKey)), persisted);
    });

    test('replace updates store and persists', () async {
      const updated = TimeOfDay(hour: 9, minute: 0);

      when(mockedPreferenceRepository.shipByKey(startOfDayKey))
          .thenAnswer((_) async => PreferenceEntity(startOfDayKey, defaultStartOfDay));
      when(mockedPreferenceRepository.shipByKey(notifyAfterInactivity))
          .thenAnswer((_) async => PreferenceEntity(
                notifyAfterInactivity,
                defaultNotifyAfterInactivity,
              ));
      when(mockedPreferenceRepository.receive(any))
          .thenAnswer((_) async => true);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      await container
          .read(preferenceProvider(startOfDayKey).notifier)
          .replace(updated);

      expect(container.read(preferenceProvider(startOfDayKey)), updated);

      final captured = verify(mockedPreferenceRepository.receive(captureAny))
          .captured
          .single as PreferenceEntity;
      expect(captured.key, startOfDayKey);
      expect(captured.value, updated);
    });
  });
}
