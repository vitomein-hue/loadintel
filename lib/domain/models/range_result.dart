class RangeResult {
  const RangeResult({
    required this.id,
    required this.loadId,
    required this.testedAt,
    required this.firearmId,
    required this.distanceYds,
    this.fpsShots,
    this.avgFps,
    this.sdFps,
    this.esFps,
    required this.groupSizeIn,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String loadId;
  final DateTime testedAt;
  final String firearmId;
  final double distanceYds;
  final List<double>? fpsShots;
  final double? avgFps;
  final double? sdFps;
  final double? esFps;
  final double groupSizeIn;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  RangeResult copyWith({
    String? id,
    String? loadId,
    DateTime? testedAt,
    String? firearmId,
    double? distanceYds,
    List<double>? fpsShots,
    double? avgFps,
    double? sdFps,
    double? esFps,
    double? groupSizeIn,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RangeResult(
      id: id ?? this.id,
      loadId: loadId ?? this.loadId,
      testedAt: testedAt ?? this.testedAt,
      firearmId: firearmId ?? this.firearmId,
      distanceYds: distanceYds ?? this.distanceYds,
      fpsShots: fpsShots ?? this.fpsShots,
      avgFps: avgFps ?? this.avgFps,
      sdFps: sdFps ?? this.sdFps,
      esFps: esFps ?? this.esFps,
      groupSizeIn: groupSizeIn ?? this.groupSizeIn,
      notes: notes ?? this.notes,
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
      'fpsShots': fpsShotsJson,
      'avgFps': avgFps,
      'sdFps': sdFps,
      'esFps': esFps,
      'groupSizeIn': groupSizeIn,
      'notes': notes,
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
      fpsShots: fpsShots,
      avgFps: (map['avgFps'] as num?)?.toDouble(),
      sdFps: (map['sdFps'] as num?)?.toDouble(),
      esFps: (map['esFps'] as num?)?.toDouble(),
      groupSizeIn: (map['groupSizeIn'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

