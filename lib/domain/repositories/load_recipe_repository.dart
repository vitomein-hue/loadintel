import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/load_with_best_result.dart';

abstract class LoadRecipeRepository {
  Future<void> upsertRecipe(LoadRecipe recipe);
  Future<void> updateKeeper(String id, bool isKeeper);
  Future<void> deleteRecipe(String id);
  Future<LoadRecipe?> getRecipe(String id);
  Future<List<LoadRecipe>> listRecipes();
  Future<int> countRecipes();
  Future<List<LoadRecipe>> listNewLoads();
  Future<List<LoadWithBestResult>> listTestedLoads();
}
