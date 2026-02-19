import 'dart:convert';
import 'dart:io';

import 'package:loadintel/data/db/app_database.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<String> exportBackup() async {
    final db = await _db.database;
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'firearms': await db.query('firearms'),
      'loadRecipes': await db.query('load_recipes'),
      'rangeResults': await db.query('range_results'),
      'targetPhotos': await db.query('target_photos'),
      'inventory': await db.query('inventory'),
      'settings': await db.query('settings'),
    };

    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(path.join(directory.path, 'exports'));
    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = path.join(
      exportDir.path,
      'loadintel_backup_$timestamp.json',
    );
    final file = File(filePath);
    await file.writeAsString(jsonEncode(payload));
    return filePath;
  }

  Future<void> importBackup(String filePath) async {
    final file = File(filePath);
    final raw = await file.readAsString();
    final payload = jsonDecode(raw) as Map<String, dynamic>;
    final db = await _db.database;

    final firearms = List<Map<String, dynamic>>.from(
      payload['firearms'] as List,
    );
    final loadRecipes = List<Map<String, dynamic>>.from(
      payload['loadRecipes'] as List,
    );
    final rangeResults = List<Map<String, dynamic>>.from(
      payload['rangeResults'] as List,
    );
    final targetPhotos = List<Map<String, dynamic>>.from(
      payload['targetPhotos'] as List,
    );
    final inventory = List<Map<String, dynamic>>.from(
      payload['inventory'] as List,
    );
    final settings = List<Map<String, dynamic>>.from(
      payload['settings'] as List,
    );

    await db.transaction((txn) async {
      await txn.delete('target_photos');
      await txn.delete('range_results');
      await txn.delete('load_recipes');
      await txn.delete('firearms');
      await txn.delete('inventory');
      await txn.delete('settings');

      for (final row in firearms) {
        await txn.insert('firearms', row);
      }
      for (final row in loadRecipes) {
        await txn.insert('load_recipes', row);
      }
      for (final row in rangeResults) {
        await txn.insert('range_results', row);
      }
      for (final row in targetPhotos) {
        await txn.insert('target_photos', row);
      }
      for (final row in inventory) {
        await txn.insert('inventory', row);
      }
      for (final row in settings) {
        await txn.insert('settings', row);
      }
    });
  }
}
