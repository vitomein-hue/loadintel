import 'package:loadintel/data/db/app_database.dart';
import 'package:loadintel/domain/models/firearm.dart';
import 'package:loadintel/domain/repositories/firearm_repository.dart';
import 'package:sqflite/sqflite.dart';

class FirearmRepositorySqlite implements FirearmRepository {
  FirearmRepositorySqlite(this._db);

  final AppDatabase _db;

  @override
  Future<void> upsertFirearm(Firearm firearm) async {
    final db = await _db.database;
    await db.insert(
      'firearms',
      firearm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteFirearm(String id) async {
    final db = await _db.database;
    await db.delete('firearms', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Firearm?> getFirearm(String id) async {
    final db = await _db.database;
    final rows = await db.query('firearms', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      return null;
    }
    return Firearm.fromMap(rows.first);
  }

  @override
  Future<List<Firearm>> listFirearms() async {
    final db = await _db.database;
    final rows = await db.query('firearms', orderBy: 'name ASC');
    return rows.map(Firearm.fromMap).toList();
  }
}

