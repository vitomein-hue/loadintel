import 'package:loadintel/core/utils/date_time_codec.dart';
import 'package:loadintel/data/db/app_database.dart';
import 'package:loadintel/domain/models/inventory_item.dart';
import 'package:loadintel/domain/repositories/inventory_repository.dart';
import 'package:sqflite/sqflite.dart';

class InventoryRepositorySqlite implements InventoryRepository {
  InventoryRepositorySqlite(this._db);

  final AppDatabase _db;

  @override
  Future<void> upsertItem(InventoryItem item) async {
    final db = await _db.database;
    await db.insert(
      'inventory',
      item.toMap(
        createdAtMillis: encodeDateTime(item.createdAt),
        updatedAtMillis: encodeDateTime(item.updatedAt),
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    final db = await _db.database;
    await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<InventoryItem?> getItem(String id) async {
    final db = await _db.database;
    final rows = await db.query('inventory', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      return null;
    }
    return _mapItem(rows.first);
  }

  @override
  Future<List<InventoryItem>> listItems() async {
    final db = await _db.database;
    final rows = await db.query('inventory', orderBy: 'name ASC');
    return rows.map(_mapItem).toList();
  }

  InventoryItem _mapItem(Map<String, Object?> row) {
    return InventoryItem.fromMap(
      map: row,
      createdAt: decodeDateTime(row['createdAt'] as int),
      updatedAt: decodeDateTime(row['updatedAt'] as int),
    );
  }
}

