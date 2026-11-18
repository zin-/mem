import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/settings/files_client.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  late FilePickerPlatform original;

  setUp(() {
    original = FilePickerPlatform.instance;
  });

  tearDown(() {
    FilePickerPlatform.instance = original;
  });

  group('FilesClient.pick', () {
    test('returns null when the picker is cancelled', () async {
      FilePickerPlatform.instance = _PickFileOnly(null);

      expect(await FilesClient().pick(), isNull);
    });

    test('returns a list containing only the picked xFile', () async {
      final xFile = XFile('/tmp/backup.db');
      FilePickerPlatform.instance = _PickFileOnly(_PickedFile(xFile));

      expect(await FilesClient().pick(), [xFile]);
    });
  });
}

class _PickFileOnly extends FilePickerPlatform {
  _PickFileOnly(this._file);

  final PlatformFile? _file;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async =>
      _file;
}

base class _PickedFile extends PlatformFile {
  _PickedFile(this.xFile);

  @override
  final XFile xFile;

  @override
  String get name => xFile.name;

  @override
  Uri get uri => Uri.file(xFile.path);

  @override
  int? lengthSync() => throw UnimplementedError();

  @override
  Future<int?> length() => throw UnimplementedError();

  @override
  Future<Uint8List> readAsBytes() => throw UnimplementedError();

  @override
  Stream<Uint8List> readAsByteStream() => throw UnimplementedError();
}
