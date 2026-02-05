class LoadRecipe {
  const LoadRecipe({
    required this.id,
    required this.recipeName,
    required this.cartridge,
    this.bulletBrand,
    this.bulletWeightGr,
    this.bulletDiameter,
    this.bulletType,
    this.brass,
    this.brassTrimLength,
    this.annealingTimeSec,
    this.primer,
    this.caseResize,
    this.gasCheckMaterial,
    this.gasCheckInstallMethod,
    this.bulletCoating,
    required this.powder,
    required this.powderChargeGr,
    this.coal,
    this.baseToOgive,
    this.seatingDepth,
    this.notes,
    required this.firearmId,
    required this.isDangerous,
    this.dangerConfirmedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String recipeName;
  final String cartridge;
  final String? bulletBrand;
  final double? bulletWeightGr;
  final double? bulletDiameter;
  final String? bulletType;
  final String? brass;
  final double? brassTrimLength;
  final double? annealingTimeSec;
  final String? primer;
  final String? caseResize;
  final String? gasCheckMaterial;
  final String? gasCheckInstallMethod;
  final String? bulletCoating;
  final String powder;
  final double powderChargeGr;
  final double? coal;
  final double? baseToOgive;
  final double? seatingDepth;
  final String? notes;
  final String firearmId;
  final bool isDangerous;
  final DateTime? dangerConfirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoadRecipe copyWith({
    String? id,
    String? recipeName,
    String? cartridge,
    String? bulletBrand,
    double? bulletWeightGr,
    double? bulletDiameter,
    String? bulletType,
    String? brass,
    double? brassTrimLength,
    double? annealingTimeSec,
    String? primer,
    String? caseResize,
    String? gasCheckMaterial,
    String? gasCheckInstallMethod,
    String? bulletCoating,
    String? powder,
    double? powderChargeGr,
    double? coal,
    double? baseToOgive,
    double? seatingDepth,
    String? notes,
    String? firearmId,
    bool? isDangerous,
    DateTime? dangerConfirmedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoadRecipe(
      id: id ?? this.id,
      recipeName: recipeName ?? this.recipeName,
      cartridge: cartridge ?? this.cartridge,
      bulletBrand: bulletBrand ?? this.bulletBrand,
      bulletWeightGr: bulletWeightGr ?? this.bulletWeightGr,
      bulletDiameter: bulletDiameter ?? this.bulletDiameter,
      bulletType: bulletType ?? this.bulletType,
      brass: brass ?? this.brass,
      brassTrimLength: brassTrimLength ?? this.brassTrimLength,
      annealingTimeSec: annealingTimeSec ?? this.annealingTimeSec,
      primer: primer ?? this.primer,
      caseResize: caseResize ?? this.caseResize,
      gasCheckMaterial: gasCheckMaterial ?? this.gasCheckMaterial,
      gasCheckInstallMethod:
          gasCheckInstallMethod ?? this.gasCheckInstallMethod,
      bulletCoating: bulletCoating ?? this.bulletCoating,
      powder: powder ?? this.powder,
      powderChargeGr: powderChargeGr ?? this.powderChargeGr,
      coal: coal ?? this.coal,
      baseToOgive: baseToOgive ?? this.baseToOgive,
      seatingDepth: seatingDepth ?? this.seatingDepth,
      notes: notes ?? this.notes,
      firearmId: firearmId ?? this.firearmId,
      isDangerous: isDangerous ?? this.isDangerous,
      dangerConfirmedAt: dangerConfirmedAt ?? this.dangerConfirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap({
    required int createdAtMillis,
    required int updatedAtMillis,
    int? dangerConfirmedAtMillis,
  }) {
    return {
      'id': id,
      'recipeName': recipeName,
      'cartridge': cartridge,
      'bulletBrand': bulletBrand,
      'bulletWeightGr': bulletWeightGr,
      'bulletDiameter': bulletDiameter,
      'bulletType': bulletType,
      'brass': brass,
      'brassTrimLength': brassTrimLength,
      'annealingTimeSec': annealingTimeSec,
      'primer': primer,
      'caseResize': caseResize,
      'gasCheckMaterial': gasCheckMaterial,
      'gasCheckInstallMethod': gasCheckInstallMethod,
      'bulletCoating': bulletCoating,
      'powder': powder,
      'powderChargeGr': powderChargeGr,
      'coal': coal,
      'baseToOgive': baseToOgive,
      'seatingDepth': seatingDepth,
      'notes': notes,
      'firearmId': firearmId,
      'isDangerous': isDangerous ? 1 : 0,
      'dangerConfirmedAt': dangerConfirmedAtMillis,
      'createdAt': createdAtMillis,
      'updatedAt': updatedAtMillis,
    };
  }

  static LoadRecipe fromMap({
    required Map<String, Object?> map,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? dangerConfirmedAt,
  }) {
    return LoadRecipe(
      id: map['id'] as String,
      recipeName: map['recipeName'] as String,
      cartridge: map['cartridge'] as String,
      bulletBrand: map['bulletBrand'] as String?,
      bulletWeightGr: (map['bulletWeightGr'] as num?)?.toDouble(),
      bulletDiameter: (map['bulletDiameter'] as num?)?.toDouble(),
      bulletType: map['bulletType'] as String?,
      brass: map['brass'] as String?,
      brassTrimLength: (map['brassTrimLength'] as num?)?.toDouble(),
      annealingTimeSec: (map['annealingTimeSec'] as num?)?.toDouble(),
      primer: map['primer'] as String?,
      caseResize: map['caseResize'] as String?,
      gasCheckMaterial: map['gasCheckMaterial'] as String?,
      gasCheckInstallMethod: map['gasCheckInstallMethod'] as String?,
      bulletCoating: map['bulletCoating'] as String?,
      powder: map['powder'] as String,
      powderChargeGr: (map['powderChargeGr'] as num).toDouble(),
      coal: (map['coal'] as num?)?.toDouble(),
      baseToOgive: (map['baseToOgive'] as num?)?.toDouble(),
      seatingDepth: (map['seatingDepth'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      firearmId: map['firearmId'] as String,
      isDangerous: (map['isDangerous'] as int? ?? 0) == 1,
      dangerConfirmedAt: dangerConfirmedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
