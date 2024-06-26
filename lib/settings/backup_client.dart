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

  Future<Object?> restore() => v(
        () async {
          final pickedFiles = await _filesClient.pick();

          // if (pickedFiles != null &&
          //     pickedFiles.isNotEmpty &&
          //     pickedFiles.length == 1) {
          //   final picked = pickedFiles.single;
          //   // TODO check file name
          //   //  DBの形式なのかとかも見たほうがよいかも？
          //   //  名前より、配置して読み込んでみてアクセスできそうかを見たほうが良いかも
          //   // TODO 元のファイルを日時付きで名前変更して置いておく？
          //   //  で、新しいファイルを通常の名前にして置き換えるか
          //   return picked.name;
          // }

          return pickedFiles;
        },
      );
}
