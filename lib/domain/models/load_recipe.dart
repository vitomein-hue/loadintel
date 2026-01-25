class LoadRecipe {
  const LoadRecipe({
    required this.id,
    required this.recipeName,
    required this.cartridge,
    this.bulletBrand,
    this.bulletWeightGr,
    this.bulletType,
    this.brass,
    this.primer,
    required this.powder,
    required this.powderChargeGr,
    this.coal,
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
  final String? bulletType;
  final String? brass;
  final String? primer;
  final String powder;
  final double powderChargeGr;
  final double? coal;
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
    String? bulletType,
    String? brass,
    String? primer,
    String? powder,
    double? powderChargeGr,
    double? coal,
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
      bulletType: bulletType ?? this.bulletType,
      brass: brass ?? this.brass,
      primer: primer ?? this.primer,
      powder: powder ?? this.powder,
      powderChargeGr: powderChargeGr ?? this.powderChargeGr,
      coal: coal ?? this.coal,
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
      'bulletType': bulletType,
      'brass': brass,
      'primer': primer,
      'powder': powder,
      'powderChargeGr': powderChargeGr,
      'coal': coal,
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
      bulletType: map['bulletType'] as String?,
      brass: map['brass'] as String?,
      primer: map['primer'] as String?,
      powder: map['powder'] as String,
      powderChargeGr: (map['powderChargeGr'] as num).toDouble(),
      coal: (map['coal'] as num?)?.toDouble(),
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

