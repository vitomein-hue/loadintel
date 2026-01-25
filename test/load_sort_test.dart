import 'package:flutter_test/flutter_test.dart';
import 'package:loadintel/core/utils/load_sort.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/load_with_best_result.dart';
import 'package:loadintel/domain/models/range_result.dart';

void main() {
  test('sortTestedLoads groups by cartridge and best group ascending', () {
    final now = DateTime.now();
    final loadA = LoadRecipe(
      id: 'a',
      recipeName: 'Alpha',
      cartridge: '308',
      powder: 'Varget',
      powderChargeGr: 44,
      firearmId: 'f1',
      isDangerous: false,
      createdAt: now,
      updatedAt: now,
    );
    final loadB = LoadRecipe(
      id: 'b',
      recipeName: 'Bravo',
      cartridge: '6.5',
      powder: 'H4350',
      powderChargeGr: 41,
      firearmId: 'f1',
      isDangerous: false,
      createdAt: now,
      updatedAt: now,
    );
    final loadC = LoadRecipe(
      id: 'c',
      recipeName: 'Charlie',
      cartridge: '308',
      powder: 'Varget',
      powderChargeGr: 43,
      firearmId: 'f1',
      isDangerous: false,
      createdAt: now,
      updatedAt: now,
    );

    final bestA = RangeResult(
      id: 'ra',
      loadId: 'a',
      testedAt: now,
      firearmId: 'f1',
      distanceYds: 100,
      avgFps: 2700,
      groupSizeIn: 1.1,
      createdAt: now,
      updatedAt: now,
    );
    final bestB = RangeResult(
      id: 'rb',
      loadId: 'b',
      testedAt: now,
      firearmId: 'f1',
      distanceYds: 100,
      avgFps: 2800,
      groupSizeIn: 0.5,
      createdAt: now,
      updatedAt: now,
    );
    final bestC = RangeResult(
      id: 'rc',
      loadId: 'c',
      testedAt: now,
      firearmId: 'f1',
      distanceYds: 100,
      avgFps: 2680,
      groupSizeIn: 0.8,
      createdAt: now,
      updatedAt: now,
    );

    final loads = [
      LoadWithBestResult(recipe: loadA, bestResult: bestA, resultCount: 2),
      LoadWithBestResult(recipe: loadB, bestResult: bestB, resultCount: 1),
      LoadWithBestResult(recipe: loadC, bestResult: bestC, resultCount: 1),
    ];

    final sorted = sortTestedLoads(loads);
    expect(sorted[0].recipe.id, 'b');
    expect(sorted[1].recipe.id, 'c');
    expect(sorted[2].recipe.id, 'a');
  });
}
