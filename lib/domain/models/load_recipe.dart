enum LoadType { rifle, shotgun, muzzleloader }

extension LoadTypeX on LoadType {
  String get storageValue {
    switch (this) {
      case LoadType.rifle:
        return 'rifle';
      case LoadType.shotgun:
        return 'shotgun';
      case LoadType.muzzleloader:
        return 'muzzleloader';
    }
  }

  String get label {
    switch (this) {
      case LoadType.rifle:
        return 'Rifle/Pistol';
      case LoadType.shotgun:
        return 'Shotgun';
      case LoadType.muzzleloader:
        return 'Muzzleloader';
    }
  }

  static LoadType fromStorage(String? value) {
    switch (value) {
      case 'shotgun':
        return LoadType.shotgun;
      case 'muzzleloader':
        return LoadType.muzzleloader;
      case 'rifle':
      default:
        return LoadType.rifle;
    }
  }
}

class LoadRecipe {
  static const Object _unset = Object();
  static final RegExp _duplicateSuffixPattern = RegExp(
    r'^(.*?)(?:\s*\((\d+)\))$',
  );

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
    this.firearmId,
    this.loadType = LoadType.rifle,
    this.gauge,
    this.shellLength,
    this.hull,
    this.shotgunPrimer,
    this.shotgunPowder,
    this.shotgunPowderCharge,
    this.wad,
    this.shotWeight,
    this.shotSize,
    this.shotType,
    this.crimpType,
    this.dramEquivalent,
    this.muzzleloaderCaliber,
    this.ignitionType,
    this.muzzleloaderPowderType,
    this.powderGranulation,
    this.muzzleloaderPowderCharge,
    this.projectileType,
    this.projectileSizeWeight,
    this.patchMaterial,
    this.patchThickness,
    this.patchLube,
    this.sabotType,
    this.cleanedBetweenShots,
    required this.isKeeper,
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
  final String? firearmId;
  final LoadType loadType;

  final String? gauge;
  final String? shellLength;
  final String? hull;
  final String? shotgunPrimer;
  final String? shotgunPowder;
  final double? shotgunPowderCharge;
  final String? wad;
  final String? shotWeight;
  final String? shotSize;
  final String? shotType;
  final String? crimpType;
  final double? dramEquivalent;

  final String? muzzleloaderCaliber;
  final String? ignitionType;
  final String? muzzleloaderPowderType;
  final String? powderGranulation;
  final double? muzzleloaderPowderCharge;
  final String? projectileType;
  final String? projectileSizeWeight;
  final String? patchMaterial;
  final String? patchThickness;
  final String? patchLube;
  final String? sabotType;
  final bool? cleanedBetweenShots;

  final bool isKeeper;
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
    Object? firearmId = _unset,
    LoadType? loadType,
    String? gauge,
    String? shellLength,
    String? hull,
    String? shotgunPrimer,
    String? shotgunPowder,
    double? shotgunPowderCharge,
    String? wad,
    String? shotWeight,
    String? shotSize,
    String? shotType,
    String? crimpType,
    double? dramEquivalent,
    String? muzzleloaderCaliber,
    String? ignitionType,
    String? muzzleloaderPowderType,
    String? powderGranulation,
    double? muzzleloaderPowderCharge,
    String? projectileType,
    String? projectileSizeWeight,
    String? patchMaterial,
    String? patchThickness,
    String? patchLube,
    String? sabotType,
    bool? cleanedBetweenShots,
    bool? isKeeper,
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
      firearmId: identical(firearmId, _unset)
          ? this.firearmId
          : firearmId as String?,
      loadType: loadType ?? this.loadType,
      gauge: gauge ?? this.gauge,
      shellLength: shellLength ?? this.shellLength,
      hull: hull ?? this.hull,
      shotgunPrimer: shotgunPrimer ?? this.shotgunPrimer,
      shotgunPowder: shotgunPowder ?? this.shotgunPowder,
      shotgunPowderCharge: shotgunPowderCharge ?? this.shotgunPowderCharge,
      wad: wad ?? this.wad,
      shotWeight: shotWeight ?? this.shotWeight,
      shotSize: shotSize ?? this.shotSize,
      shotType: shotType ?? this.shotType,
      crimpType: crimpType ?? this.crimpType,
      dramEquivalent: dramEquivalent ?? this.dramEquivalent,
      muzzleloaderCaliber: muzzleloaderCaliber ?? this.muzzleloaderCaliber,
      ignitionType: ignitionType ?? this.ignitionType,
      muzzleloaderPowderType:
          muzzleloaderPowderType ?? this.muzzleloaderPowderType,
      powderGranulation: powderGranulation ?? this.powderGranulation,
      muzzleloaderPowderCharge:
          muzzleloaderPowderCharge ?? this.muzzleloaderPowderCharge,
      projectileType: projectileType ?? this.projectileType,
      projectileSizeWeight: projectileSizeWeight ?? this.projectileSizeWeight,
      patchMaterial: patchMaterial ?? this.patchMaterial,
      patchThickness: patchThickness ?? this.patchThickness,
      patchLube: patchLube ?? this.patchLube,
      sabotType: sabotType ?? this.sabotType,
      cleanedBetweenShots: cleanedBetweenShots ?? this.cleanedBetweenShots,
      isKeeper: isKeeper ?? this.isKeeper,
      isDangerous: isDangerous ?? this.isDangerous,
      dangerConfirmedAt: dangerConfirmedAt ?? this.dangerConfirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  LoadRecipe duplicateForNextEntry({
    required String newId,
    required DateTime now,
  }) {
    return LoadRecipe(
      id: newId,
      recipeName: _nextDuplicateName(recipeName),
      cartridge: cartridge,
      bulletBrand: bulletBrand,
      bulletWeightGr: bulletWeightGr,
      bulletDiameter: bulletDiameter,
      bulletType: bulletType,
      brass: brass,
      brassTrimLength: brassTrimLength,
      annealingTimeSec: annealingTimeSec,
      primer: primer,
      caseResize: caseResize,
      gasCheckMaterial: gasCheckMaterial,
      gasCheckInstallMethod: gasCheckInstallMethod,
      bulletCoating: bulletCoating,
      powder: powder,
      powderChargeGr: powderChargeGr,
      coal: coal,
      baseToOgive: baseToOgive,
      seatingDepth: seatingDepth,
      notes: null,
      firearmId: firearmId,
      loadType: loadType,
      gauge: gauge,
      shellLength: shellLength,
      hull: hull,
      shotgunPrimer: shotgunPrimer,
      shotgunPowder: shotgunPowder,
      shotgunPowderCharge: shotgunPowderCharge,
      wad: wad,
      shotWeight: shotWeight,
      shotSize: shotSize,
      shotType: shotType,
      crimpType: crimpType,
      dramEquivalent: dramEquivalent,
      muzzleloaderCaliber: muzzleloaderCaliber,
      ignitionType: ignitionType,
      muzzleloaderPowderType: muzzleloaderPowderType,
      powderGranulation: powderGranulation,
      muzzleloaderPowderCharge: muzzleloaderPowderCharge,
      projectileType: projectileType,
      projectileSizeWeight: projectileSizeWeight,
      patchMaterial: patchMaterial,
      patchThickness: patchThickness,
      patchLube: patchLube,
      sabotType: sabotType,
      cleanedBetweenShots: cleanedBetweenShots,
      isKeeper: false,
      isDangerous: isDangerous,
      dangerConfirmedAt: dangerConfirmedAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _nextDuplicateName(String name) {
    final trimmed = name.trim();
    final match = _duplicateSuffixPattern.firstMatch(trimmed);
    if (match == null) {
      return '$trimmed (1)';
    }
    final base = match.group(1)!.trimRight();
    final current = int.tryParse(match.group(2) ?? '') ?? 0;
    final next = current + 1;
    return '${base.isEmpty ? trimmed : base} ($next)';
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
      'loadType': loadType.storageValue,
      'gauge': gauge,
      'shellLength': shellLength,
      'hull': hull,
      'shotgunPrimer': shotgunPrimer,
      'shotgunPowder': shotgunPowder,
      'shotgunPowderCharge': shotgunPowderCharge,
      'wad': wad,
      'shotWeight': shotWeight,
      'shotSize': shotSize,
      'shotType': shotType,
      'crimpType': crimpType,
      'dramEquivalent': dramEquivalent,
      'muzzleloaderCaliber': muzzleloaderCaliber,
      'ignitionType': ignitionType,
      'muzzleloaderPowderType': muzzleloaderPowderType,
      'powderGranulation': powderGranulation,
      'muzzleloaderPowderCharge': muzzleloaderPowderCharge,
      'projectileType': projectileType,
      'projectileSizeWeight': projectileSizeWeight,
      'patchMaterial': patchMaterial,
      'patchThickness': patchThickness,
      'patchLube': patchLube,
      'sabotType': sabotType,
      'cleanedBetweenShots': cleanedBetweenShots == null
          ? null
          : (cleanedBetweenShots! ? 1 : 0),
      'isKeeper': isKeeper ? 1 : 0,
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
      firearmId: map['firearmId'] as String?,
      loadType: LoadTypeX.fromStorage(map['loadType'] as String?),
      gauge: map['gauge'] as String?,
      shellLength: map['shellLength'] as String?,
      hull: map['hull'] as String?,
      shotgunPrimer: map['shotgunPrimer'] as String?,
      shotgunPowder: map['shotgunPowder'] as String?,
      shotgunPowderCharge: (map['shotgunPowderCharge'] as num?)?.toDouble(),
      wad: map['wad'] as String?,
      shotWeight: map['shotWeight'] as String?,
      shotSize: map['shotSize'] as String?,
      shotType: map['shotType'] as String?,
      crimpType: map['crimpType'] as String?,
      dramEquivalent: (map['dramEquivalent'] as num?)?.toDouble(),
      muzzleloaderCaliber: map['muzzleloaderCaliber'] as String?,
      ignitionType: map['ignitionType'] as String?,
      muzzleloaderPowderType: map['muzzleloaderPowderType'] as String?,
      powderGranulation: map['powderGranulation'] as String?,
      muzzleloaderPowderCharge: (map['muzzleloaderPowderCharge'] as num?)
          ?.toDouble(),
      projectileType: map['projectileType'] as String?,
      projectileSizeWeight: map['projectileSizeWeight'] as String?,
      patchMaterial: map['patchMaterial'] as String?,
      patchThickness: map['patchThickness'] as String?,
      patchLube: map['patchLube'] as String?,
      sabotType: map['sabotType'] as String?,
      cleanedBetweenShots: map['cleanedBetweenShots'] == null
          ? null
          : (map['cleanedBetweenShots'] as int) == 1,
      isKeeper: (map['isKeeper'] as int? ?? 0) == 1,
      isDangerous: (map['isDangerous'] as int? ?? 0) == 1,
      dangerConfirmedAt: dangerConfirmedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
