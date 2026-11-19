class AppVersion {
  final String text;

  AppVersion._(this.text);

  static AppVersion? of({
    required String version,
    required String buildNumber,
  }) {
    if (version.isEmpty || buildNumber.isEmpty) return null;
    return AppVersion._('$version+$buildNumber');
  }
}
