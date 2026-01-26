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
      version: 3,
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
        primer TEXT,
        caseResize TEXT,
        gasCheckMaterial TEXT,
        gasCheckInstallMethod TEXT,
        bulletCoating TEXT,
        powder TEXT NOT NULL,
        powderChargeGr REAL NOT NULL,
        coal REAL,
        seatingDepth REAL,
        notes TEXT,
        firearmId TEXT NOT NULL,
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
        fpsShots TEXT,
        avgFps REAL,
        sdFps REAL,
        esFps REAL,
        groupSizeIn REAL NOT NULL,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (loadId) REFERENCES load_recipes(id) ON DELETE CASCADE,
        FOREIGN KEY (firearmId) REFERENCES firearms(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_range_results_load ON range_results(loadId)'
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

  Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE load_recipes ADD COLUMN caseResize TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN gasCheckMaterial TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN gasCheckInstallMethod TEXT');
      await db.execute('ALTER TABLE load_recipes ADD COLUMN bulletCoating TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE load_recipes ADD COLUMN bulletDiameter REAL');
    }
  }
}

