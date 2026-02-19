import 'package:loadintel/core/utils/date_time_codec.dart';
import 'package:loadintel/core/utils/double_list_codec.dart';
import 'package:loadintel/data/db/app_database.dart';
import 'package:loadintel/domain/models/range_result.dart';
import 'package:loadintel/domain/repositories/range_result_repository.dart';
import 'package:sqflite/sqflite.dart';

class RangeResultRepositorySqlite implements RangeResultRepository {
  RangeResultRepositorySqlite(this._db);

  final AppDatabase _db;

  @override
  Future<void> addResult(RangeResult result) async {
    final db = await _db.database;
    await db.insert(
      'range_results',
      result.toMap(
        testedAtMillis: encodeDateTime(result.testedAt),
        createdAtMillis: encodeDateTime(result.createdAt),
        updatedAtMillis: encodeDateTime(result.updatedAt),
        fpsShotsJson: encodeDoubleList(result.fpsShots),
      ),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateResult(RangeResult result) async {
    final db = await _db.database;
    await db.update(
      'range_results',
      result.toMap(
        testedAtMillis: encodeDateTime(result.testedAt),
        createdAtMillis: encodeDateTime(result.createdAt),
        updatedAtMillis: encodeDateTime(result.updatedAt),
        fpsShotsJson: encodeDoubleList(result.fpsShots),
      ),
      where: 'id = ?',
      whereArgs: [result.id],
    );
  }

  @override
  Future<void> deleteResult(String id) async {
    final db = await _db.database;
    await db.delete('range_results', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<RangeResult?> getResult(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'range_results',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapRangeResult(rows.first);
  }

  @override
  Future<List<RangeResult>> listResultsByLoad(String loadId) async {
    final db = await _db.database;
    final rows = await db.query(
      'range_results',
      where: 'loadId = ?',
      whereArgs: [loadId],
      orderBy: 'testedAt DESC',
    );
    return rows.map(_mapRangeResult).toList();
  }

  @override
  Future<RangeResult?> getBestResultForLoad(String loadId) async {
    final db = await _db.database;
    final rows = await db.query(
      'range_results',
      where: 'loadId = ?',
      whereArgs: [loadId],
      orderBy: 'groupSizeIn ASC, testedAt ASC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapRangeResult(rows.first);
  }

  RangeResult _mapRangeResult(Map<String, Object?> row) {
    final testedAt = decodeDateTime(row['testedAt'] as int);
    final createdAt = decodeDateTime(row['createdAt'] as int);
    final updatedAt = decodeDateTime(row['updatedAt'] as int);
    final fpsShots = decodeDoubleList(row['fpsShots']);
    return RangeResult.fromMap(
      map: row,
      testedAt: testedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fpsShots: fpsShots,
    );
  }
}
