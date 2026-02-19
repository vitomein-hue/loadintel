import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({Database? database}) : _database = database;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, 'loadintel.db');
    final db = await openDatabase(
      fullPath,
      version: 11,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    _database = db;
    return db;
  }

  Future<void> close() async {
    final existing = _database;
    if (existing != null) {
      await existing.close();
    }
    _database = null;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE firearms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE load_recipes (
        id TEXT PRIMARY KEY,
        recipeName TEXT NOT NULL,
        cartridge TEXT NOT NULL,
        bulletBrand TEXT,
        bulletWeightGr REAL,
        bulletDiameter REAL,
        bulletType TEXT,
        brass TEXT,
        brassTrimLength REAL,
        annealingTimeSec REAL,
        primer TEXT,
        caseResize TEXT,
        gasCheckMaterial TEXT,
        gasCheckInstallMethod TEXT,
        bulletCoating TEXT,
        powder TEXT NOT NULL,
        powderChargeGr REAL NOT NULL,
        coal REAL,
        baseToOgive REAL,
        seatingDepth REAL,
        notes TEXT,
        firearmId TEXT,
        loadType TEXT NOT NULL DEFAULT 'rifle',
        gauge TEXT,
        shellLength TEXT,
        hull TEXT,
        shotgunPrimer TEXT,
        shotgunPowder TEXT,
        shotgunPowderCharge REAL,
        wad TEXT,
        shotWeight TEXT,
        shotSize TEXT,
        shotType TEXT,
        crimpType TEXT,
        dramEquivalent REAL,
        muzzleloaderCaliber TEXT,
        ignitionType TEXT,
        muzzleloaderPowderType TEXT,
        powderGranulation TEXT,
        muzzleloaderPowderCharge REAL,
        projectileType TEXT,
        projectileSizeWeight TEXT,
        patchMaterial TEXT,
        patchThickness TEXT,
        patchLube TEXT,
        sabotType TEXT,
        cleanedBetweenShots INTEGER,
        isKeeper INTEGER NOT NULL DEFAULT 0,
        isDangerous INTEGER NOT NULL DEFAULT 0,
        dangerConfirmedAt INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (firearmId) REFERENCES firearms(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE range_results (
        id TEXT PRIMARY KEY,
        loadId TEXT NOT NULL,
        testedAt INTEGER NOT NULL,
        firearmId TEXT NOT NULL,
        distanceYds REAL NOT NULL,
        roundsTested INTEGER,
        fpsShots TEXT,
        avgFps REAL,
        sdFps REAL,
        esFps REAL,
        groupSizeIn REAL NOT NULL,
        notes TEXT,
        temperatureF REAL,
        humidity REAL,
        barometricPressureInHg REAL,
        windDirection TEXT,
        windSpeedMph REAL,
        weatherConditions TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (loadId) REFERENCES load_recipes(id) ON DELETE CASCADE,
        FOREIGN KEY (firearmId) REFERENCES firearms(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_range_results_load ON range_results(loadId)',
    );

    await db.execute('''
      CREATE TABLE target_photos (
        id TEXT PRIMARY KEY,
        rangeResultId TEXT NOT NULL,
        galleryPath TEXT NOT NULL,
        thumbPath TEXT,
        FOREIGN KEY (rangeResultId) REFERENCES range_results(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        qty REAL,
        unit TEXT,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE load_recipes ADD COLUMN caseResize TEXT');
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN gasCheckMaterial TEXT',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN gasCheckInstallMethod TEXT',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN bulletCoating TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN bulletDiameter REAL',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN annealingTimeSec REAL',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN brassTrimLength REAL',
      );
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE load_recipes ADD COLUMN baseToOgive REAL');
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE range_results ADD COLUMN roundsTested INTEGER',
      );
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE range_results ADD COLUMN temperatureF REAL',
      );
      await db.execute('ALTER TABLE range_results ADD COLUMN humidity REAL');
      await db.execute(
        'ALTER TABLE range_results ADD COLUMN barometricPressureInHg REAL',
      );
      await db.execute(
        'ALTER TABLE range_results ADD COLUMN windDirection TEXT',
      );
      await db.execute(
        'ALTER TABLE range_results ADD COLUMN windSpeedMph REAL',
      );
      await db.execute(
        'ALTER TABLE range_results ADD COLUMN weatherConditions TEXT',
      );
    }
    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN isKeeper INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 10) {
      await db.execute('PRAGMA foreign_keys = OFF');
      await db.execute('''
        CREATE TABLE load_recipes_new (
          id TEXT PRIMARY KEY,
          recipeName TEXT NOT NULL,
          cartridge TEXT NOT NULL,
          bulletBrand TEXT,
          bulletWeightGr REAL,
          bulletDiameter REAL,
          bulletType TEXT,
          brass TEXT,
          brassTrimLength REAL,
          annealingTimeSec REAL,
          primer TEXT,
          caseResize TEXT,
          gasCheckMaterial TEXT,
          gasCheckInstallMethod TEXT,
          bulletCoating TEXT,
          powder TEXT NOT NULL,
          powderChargeGr REAL NOT NULL,
          coal REAL,
          baseToOgive REAL,
          seatingDepth REAL,
          notes TEXT,
          firearmId TEXT,
          isKeeper INTEGER NOT NULL DEFAULT 0,
          isDangerous INTEGER NOT NULL DEFAULT 0,
          dangerConfirmedAt INTEGER,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY (firearmId) REFERENCES firearms(id) ON DELETE RESTRICT
        )
      ''');
      await db.execute('''
        INSERT INTO load_recipes_new (
          id,
          recipeName,
          cartridge,
          bulletBrand,
          bulletWeightGr,
          bulletDiameter,
          bulletType,
          brass,
          brassTrimLength,
          annealingTimeSec,
          primer,
          caseResize,
          gasCheckMaterial,
          gasCheckInstallMethod,
          bulletCoating,
          powder,
          powderChargeGr,
          coal,
          baseToOgive,
          seatingDepth,
          notes,
          firearmId,
          isKeeper,
          isDangerous,
          dangerConfirmedAt,
          createdAt,
          updatedAt
        )
        SELECT
          id,
          recipeName,
          cartridge,
          bulletBrand,
          bulletWeightGr,
          bulletDiameter,
          bulletType,
          brass,
          brassTrimLength,
          annealingTimeSec,
          primer,
          caseResize,
          gasCheckMaterial,
          gasCheckInstallMethod,
          bulletCoating,
          powder,
          powderChargeGr,
          coal,
          baseToOgive,
          seatingDepth,
          notes,
          firearmId,
          isKeeper,
          isDangerous,
          dangerConfirmedAt,
          createdAt,
          updatedAt
        FROM load_recipes
      ''');
      await db.execute('DROP TABLE load_recipes');
      await db.execute('ALTER TABLE load_recipes_new RENAME TO load_recipes');
      await db.execute('PRAGMA foreign_keys = ON');
    }
    if (oldVersion < 11) {
      await db.execute(
        "ALTER TABLE load_recipes ADD COLUMN loadType TEXT NOT NULL DEFAULT 'rifle'",
      );
      await db.execute('ALTER TABLE load_recipes ADD COLUMN gauge TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN shellLength TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN hull TEXT');
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN shotgunPrimer TEXT',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN shotgunPowder TEXT',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN shotgunPowderCharge REAL',
      );
      await db.execute('ALTER TABLE load_recipes ADD COLUMN wad TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN shotWeight TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN shotSize TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN shotType TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN crimpType TEXT');
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN dramEquivalent REAL',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN muzzleloaderCaliber TEXT',
      );
      await db.execute('ALTER TABLE load_recipes ADD COLUMN ignitionType TEXT');
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN muzzleloaderPowderType TEXT',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN powderGranulation TEXT',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN muzzleloaderPowderCharge REAL',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN projectileType TEXT',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN projectileSizeWeight TEXT',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN patchMaterial TEXT',
      );
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN patchThickness TEXT',
      );
      await db.execute('ALTER TABLE load_recipes ADD COLUMN patchLube TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN sabotType TEXT');
      await db.execute(
        'ALTER TABLE load_recipes ADD COLUMN cleanedBetweenShots INTEGER',
      );
    }
  }
}
