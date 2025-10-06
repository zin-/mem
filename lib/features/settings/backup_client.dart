import 'dart:io';

import 'package:mem/features/settings/files_client.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/framework/repository/database_repository.dart';
import 'package:mem/features/logger/log_service.dart';

class BackupClient {
  final DatabaseRepository _databaseRepository;
  final FilesClient _filesClient;

  Future<String> createBackup() => v(
        () async => await _filesClient.saveOrShare((await _databaseRepository
            .shipFileByNameIs(databaseDefinition.name))!),
      );

  Future<String?> restore() => v(
        () async {
          final pickedFiles = await _filesClient.pick();

          if (pickedFiles != null && pickedFiles.length == 1) {
            final pickedFile = pickedFiles.single;
            // FIXME とりあえず.dbファイルを置き換えているだけ
            //  対象ファイルが不正だった場合などを考慮していない
            //  置き換え後、repositoryなどの再読み込みが必要かもしれないが考慮していない
            await _databaseRepository.replace(
                databaseDefinition.name, File(pickedFile.path));

            return pickedFile.name;
          }

          return null;
        },
      );

  BackupClient._(
    this._databaseRepository,
    this._filesClient,
  );
  static BackupClient? _instance;
  factory BackupClient({BackupClient? mock}) => _instance ??= mock ??
      BackupClient._(
        DatabaseRepository(),
        FilesClient(),
      );
}
