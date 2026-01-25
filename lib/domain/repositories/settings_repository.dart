class SettingsKeys {
  static const String lifetimeUnlocked = 'lifetimeUnlocked';
}

abstract class SettingsRepository {
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);

  Future<void> setLifetimeUnlocked(bool value);
  Future<bool> isLifetimeUnlocked();
}

