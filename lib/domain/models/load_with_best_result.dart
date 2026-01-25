import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/range_result.dart';

class LoadWithBestResult {
  const LoadWithBestResult({
    required this.recipe,
    required this.bestResult,
    required this.resultCount,
  });

  final LoadRecipe recipe;
  final RangeResult? bestResult;
  final int resultCount;

  double? get bestGroupSize => bestResult?.groupSizeIn;
}

