import 'package:loadintel/data/db/app_database.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepositorySqlite implements SettingsRepository {
  SettingsRepositorySqlite(this._db);

  final AppDatabase _db;

  @override
  Future<void> setBool(String key, bool value) async {
    final db = await _db.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value ? '1' : '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<bool?> getBool(String key) async {
    final db = await _db.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) {
      return null;
    }
    final value = rows.first['value'] as String?;
    if (value == null) {
      return null;
    }
    return value == '1';
  }

  @override
  Future<void> setLifetimeUnlocked(bool value) async {
    await setBool(SettingsKeys.lifetimeUnlocked, value);
  }

  @override
  Future<bool> isLifetimeUnlocked() async {
    return (await getBool(SettingsKeys.lifetimeUnlocked)) ?? false;
  }
}

