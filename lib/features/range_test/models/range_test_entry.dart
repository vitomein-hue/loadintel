import 'package:loadintel/domain/models/load_recipe.dart';

class RangeTestLoadEntry {
  RangeTestLoadEntry({
    required this.recipe,
    required this.firearmId,
  });

  final LoadRecipe recipe;
  String? firearmId;
  double? distanceYds;
  FpsEntryMode fpsMode = FpsEntryMode.manual;
  List<double> shots = [];
  double? avgFps;
  double? sdFps;
  double? esFps;
}

enum FpsEntryMode { manual, shots }
