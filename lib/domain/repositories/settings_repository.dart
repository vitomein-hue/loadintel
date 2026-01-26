class SettingsKeys {
  static const String lifetimeUnlocked = 'lifetimeUnlocked';
  static const String exportFolderUri = 'exportFolderUri';
  static const String caseResizeOptions = 'caseResizeOptions';
  static const String gasCheckMaterialOptions = 'gasCheckMaterialOptions';
  static const String gasCheckInstallMethodOptions = 'gasCheckInstallMethodOptions';
  static const String bulletCoatingOptions = 'bulletCoatingOptions';
}

abstract class SettingsRepository {
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);

  Future<void> setLifetimeUnlocked(bool value);
  Future<bool> isLifetimeUnlocked();
}
