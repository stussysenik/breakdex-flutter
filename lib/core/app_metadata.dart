abstract final class AppMetadata {
  static const exportSchemaVersion = 8;
  static const appVersion = '1.1.0';
  static const buildNumber = '3';

  static const releaseVersion = '$appVersion+$buildNumber';
  static const footerLabel = 'Breakdex v$appVersion (Build $buildNumber)';
}
