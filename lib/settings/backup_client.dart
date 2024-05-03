import 'package:mem/settings/files_client.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/framework/repository/database_repository.dart';
import 'package:mem/logger/log_service.dart';

class BackupClient {
  static BackupClient? _instance;

  final DatabaseRepository _databaseRepository;
  final FilesClient _filesClient;

  BackupClient._(
    this._databaseRepository,
    this._filesClient,
  );

  factory BackupClient() => _instance ??= BackupClient._(
        DatabaseRepository(),
        FilesClient(),
      );

  Future<String> createBackup() => v(
        () async => await _filesClient.saveOrShare((await _databaseRepository
            .shipFileByNameIs(databaseDefinition.name))!),
      );
}
