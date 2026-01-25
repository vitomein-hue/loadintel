import 'package:loadintel/data/db/app_database.dart';
import 'package:loadintel/domain/models/target_photo.dart';
import 'package:loadintel/domain/repositories/target_photo_repository.dart';
import 'package:sqflite/sqflite.dart';

class TargetPhotoRepositorySqlite implements TargetPhotoRepository {
  TargetPhotoRepositorySqlite(this._db);

  final AppDatabase _db;

  @override
  Future<void> addPhoto(TargetPhoto photo) async {
    final db = await _db.database;
    await db.insert(
      'target_photos',
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deletePhoto(String id) async {
    final db = await _db.database;
    await db.delete('target_photos', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<TargetPhoto>> listPhotosForResult(String rangeResultId) async {
    final db = await _db.database;
    final rows = await db.query(
      'target_photos',
      where: 'rangeResultId = ?',
      whereArgs: [rangeResultId],
      orderBy: 'id ASC',
    );
    return rows.map(TargetPhoto.fromMap).toList();
  }
}

