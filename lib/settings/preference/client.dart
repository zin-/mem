import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/preference/keys.dart';
import 'package:mem/settings/preference/preference.dart';
import 'package:mem/settings/preference/repository.dart';

class PreferenceClient {
  final PreferenceRepository _repository;

  PreferenceClient._(this._repository);

  Future updateNotifyAfterInactivity(int? value) => v(
        () async {
          if (value == null) {
            await _repository.discard(notifyAfterInactivity);
          } else {
            await _repository.receive(
              PreferenceEntity(
                notifyAfterInactivity,
                value,
              ),
            );
          }
        },
        {
          'value': value,
        },
      );

  static PreferenceClient? _instance;

  factory PreferenceClient({
    PreferenceRepository? repository,
  }) =>
      i(
        () => _instance ??= PreferenceClient._(
          repository ?? PreferenceRepository(),
        ),
        {
          'repository': repository,
        },
      );
}
