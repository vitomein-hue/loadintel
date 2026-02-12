import 'package:loadintel/domain/models/load_recipe.dart';

class RangeTestLoadEntry {
  RangeTestLoadEntry({
    required this.recipe,
    required this.firearmId,
  });

  final LoadRecipe recipe;
  String? firearmId;
  double? distanceYds;
  int? roundsTested;
  FpsEntryMode fpsMode = FpsEntryMode.manual;
  List<double> shots = [];
  double? avgFps;
  double? sdFps;
  double? esFps;
  bool isDangerous = false;
  String? dangerReason;
  
  // Weather fields
  double? temperatureF;
  double? humidity;
  double? barometricPressureInHg;
  String? windDirection;
  double? windSpeedMph;
  String? weatherConditions;
}

enum FpsEntryMode { manual, shots }
