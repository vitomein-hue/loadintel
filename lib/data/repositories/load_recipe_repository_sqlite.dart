import 'package:loadintel/core/utils/date_time_codec.dart';
import 'package:loadintel/core/utils/double_list_codec.dart';
import 'package:loadintel/core/utils/load_sort.dart';
import 'package:loadintel/data/db/app_database.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/load_with_best_result.dart';
import 'package:loadintel/domain/models/range_result.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:sqflite/sqflite.dart';

class LoadRecipeRepositorySqlite implements LoadRecipeRepository {
  LoadRecipeRepositorySqlite(this._db);

  final AppDatabase _db;

  @override
  Future<void> upsertRecipe(LoadRecipe recipe) async {
    final db = await _db.database;
    await db.insert(
      'load_recipes',
      recipe.toMap(
        createdAtMillis: encodeDateTime(recipe.createdAt),
        updatedAtMillis: encodeDateTime(recipe.updatedAt),
        dangerConfirmedAtMillis: recipe.dangerConfirmedAt == null
            ? null
            : encodeDateTime(recipe.dangerConfirmedAt!),
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateKeeper(String id, bool isKeeper) async {
    final db = await _db.database;
    await db.update(
      'load_recipes',
      {
        'isKeeper': isKeeper ? 1 : 0,
        'updatedAt': encodeDateTime(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteRecipe(String id) async {
    final db = await _db.database;
    await db.delete('load_recipes', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<LoadRecipe?> getRecipe(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'load_recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapRecipe(rows.first);
  }

  @override
  Future<List<LoadRecipe>> listRecipes() async {
    final db = await _db.database;
    final rows = await db.query('load_recipes', orderBy: 'createdAt DESC');
    return rows.map(_mapRecipe).toList();
  }

  @override
  Future<int> countRecipes() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as count FROM load_recipes',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  @override
  Future<List<LoadRecipe>> listNewLoads() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT lr.*
      FROM load_recipes lr
      LEFT JOIN range_results rr ON rr.loadId = lr.id
      WHERE rr.id IS NULL
      ORDER BY lr.createdAt DESC
    ''');
    return rows.map(_mapRecipe).toList();
  }

  @override
  Future<List<LoadWithBestResult>> listTestedLoads() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT lr.*
      FROM load_recipes lr
      INNER JOIN range_results rr ON rr.loadId = lr.id
    ''');

    final results = <LoadWithBestResult>[];
    for (final row in rows) {
      final recipe = _mapRecipe(row);
      final bestResult = await _getBestResultForLoad(db, recipe.id);
      final count = await _countResultsForLoad(db, recipe.id);
      results.add(
        LoadWithBestResult(
          recipe: recipe,
          bestResult: bestResult,
          resultCount: count,
        ),
      );
    }

    return sortTestedLoads(results);
  }

  LoadRecipe _mapRecipe(Map<String, Object?> row) {
    final createdAt = decodeDateTime(row['createdAt'] as int);
    final updatedAt = decodeDateTime(row['updatedAt'] as int);
    final dangerConfirmedAt = decodeNullableDateTime(row['dangerConfirmedAt']);
    return LoadRecipe.fromMap(
      map: row,
      createdAt: createdAt,
      updatedAt: updatedAt,
      dangerConfirmedAt: dangerConfirmedAt,
    );
  }

  Future<RangeResult?> _getBestResultForLoad(Database db, String loadId) async {
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

  Future<int> _countResultsForLoad(Database db, String loadId) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as count FROM range_results WHERE loadId = ?',
      [loadId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
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
