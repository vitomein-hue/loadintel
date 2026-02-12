class RangeResult {
  const RangeResult({
    required this.id,
    required this.loadId,
    required this.testedAt,
    required this.firearmId,
    required this.distanceYds,
    this.roundsTested,
    this.fpsShots,
    this.avgFps,
    this.sdFps,
    this.esFps,
    required this.groupSizeIn,
    this.notes,
    this.temperatureF,
    this.humidity,
    this.barometricPressureInHg,
    this.windDirection,
    this.windSpeedMph,
    this.weatherConditions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String loadId;
  final DateTime testedAt;
  final String firearmId;
  final double distanceYds;
  final int? roundsTested;
  final List<double>? fpsShots;
  final double? avgFps;
  final double? sdFps;
  final double? esFps;
  final double groupSizeIn;
  final String? notes;
  final double? temperatureF;
  final double? humidity;
  final double? barometricPressureInHg;
  final String? windDirection;
  final double? windSpeedMph;
  final String? weatherConditions;
  final DateTime createdAt;
  final DateTime updatedAt;

  RangeResult copyWith({
    String? id,
    String? loadId,
    DateTime? testedAt,
    String? firearmId,
    double? distanceYds,
    int? roundsTested,
    List<double>? fpsShots,
    double? avgFps,
    double? sdFps,
    double? esFps,
    double? groupSizeIn,
    String? notes,
    double? temperatureF,
    double? humidity,
    double? barometricPressureInHg,
    String? windDirection,
    double? windSpeedMph,
    String? weatherConditions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RangeResult(
      id: id ?? this.id,
      loadId: loadId ?? this.loadId,
      testedAt: testedAt ?? this.testedAt,
      firearmId: firearmId ?? this.firearmId,
      distanceYds: distanceYds ?? this.distanceYds,
      roundsTested: roundsTested ?? this.roundsTested,
      fpsShots: fpsShots ?? this.fpsShots,
      avgFps: avgFps ?? this.avgFps,
      sdFps: sdFps ?? this.sdFps,
      esFps: esFps ?? this.esFps,
      groupSizeIn: groupSizeIn ?? this.groupSizeIn,
      notes: notes ?? this.notes,
      temperatureF: temperatureF ?? this.temperatureF,
      humidity: humidity ?? this.humidity,
      barometricPressureInHg: barometricPressureInHg ?? this.barometricPressureInHg,
      windDirection: windDirection ?? this.windDirection,
      windSpeedMph: windSpeedMph ?? this.windSpeedMph,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap({
    required int testedAtMillis,
    required int createdAtMillis,
    required int updatedAtMillis,
    String? fpsShotsJson,
  }) {
    return {
      'id': id,
      'loadId': loadId,
      'testedAt': testedAtMillis,
      'firearmId': firearmId,
      'distanceYds': distanceYds,
      'roundsTested': roundsTested,
      'fpsShots': fpsShotsJson,
      'avgFps': avgFps,
      'sdFps': sdFps,
      'esFps': esFps,
      'groupSizeIn': groupSizeIn,
      'notes': notes,
      'temperatureF': temperatureF,
      'humidity': humidity,
      'barometricPressureInHg': barometricPressureInHg,
      'windDirection': windDirection,
      'windSpeedMph': windSpeedMph,
      'weatherConditions': weatherConditions,
      'createdAt': createdAtMillis,
      'updatedAt': updatedAtMillis,
    };
  }

  static RangeResult fromMap({
    required Map<String, Object?> map,
    required DateTime testedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    List<double>? fpsShots,
  }) {
    return RangeResult(
      id: map['id'] as String,
      loadId: map['loadId'] as String,
      testedAt: testedAt,
      firearmId: map['firearmId'] as String,
      distanceYds: (map['distanceYds'] as num).toDouble(),
      roundsTested: map['roundsTested'] as int?,
      fpsShots: fpsShots,
      avgFps: (map['avgFps'] as num?)?.toDouble(),
      sdFps: (map['sdFps'] as num?)?.toDouble(),
      esFps: (map['esFps'] as num?)?.toDouble(),
      groupSizeIn: (map['groupSizeIn'] as num).toDouble(),
      notes: map['notes'] as String?,
      temperatureF: (map['temperatureF'] as num?)?.toDouble(),
      humidity: (map['humidity'] as num?)?.toDouble(),
      barometricPressureInHg: (map['barometricPressureInHg'] as num?)?.toDouble(),
      windDirection: map['windDirection'] as String?,
      windSpeedMph: (map['windSpeedMph'] as num?)?.toDouble(),
      weatherConditions: map['weatherConditions'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

