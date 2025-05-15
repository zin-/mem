import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FilesClient {
  static FilesClient? _instance;

  FilesClient._();

  factory FilesClient() => _instance ??= FilesClient._();

  Future<List<XFile>?> pick() => v(
        () async => (await FilePicker.platform.pickFiles())?.xFiles,
      );

  Future<String> saveOrShare(File file) => v(
        () async {
          switch (defaultTargetPlatform) {
            case TargetPlatform.android:
              final result = await Share.shareXFiles([XFile(file.path)]);

              // 何が返ってくるか憶測しかできないのでrawを返却しておく
              return result.raw;

            case TargetPlatform.windows:
              final downloadsDirectory = await getDownloadsDirectory();

              final downloadFile = File(join(
                downloadsDirectory!.path,
                basename(file.path),
              ));

              await downloadFile.writeAsBytes(await file.readAsBytes());

              return downloadFile.path;

            default:
              throw UnimplementedError(); // coverage:ignore-line
          }
        },
        {
          "file": file,
        },
      );
}
