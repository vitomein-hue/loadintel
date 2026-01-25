import 'package:flutter/material.dart';
import 'package:loadintel/core/theme/app_theme.dart';
import 'package:loadintel/data/db/app_database.dart';
import 'package:loadintel/data/repositories/firearm_repository_sqlite.dart';
import 'package:loadintel/data/repositories/inventory_repository_sqlite.dart';
import 'package:loadintel/data/repositories/load_recipe_repository_sqlite.dart';
import 'package:loadintel/data/repositories/range_result_repository_sqlite.dart';
import 'package:loadintel/data/repositories/settings_repository_sqlite.dart';
import 'package:loadintel/data/repositories/target_photo_repository_sqlite.dart';
import 'package:loadintel/domain/repositories/firearm_repository.dart';
import 'package:loadintel/domain/repositories/inventory_repository.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/range_result_repository.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/domain/repositories/target_photo_repository.dart';
import 'package:loadintel/features/home/home_screen.dart';
import 'package:loadintel/services/backup_service.dart';
import 'package:loadintel/services/export_service.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:provider/provider.dart';

class LoadIntelApp extends StatelessWidget {
  const LoadIntelApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ProxyProvider<AppDatabase, BackupService>(
          update: (_, db, previous) => previous ?? BackupService(db),
        ),
        Provider<FirearmRepository>(
          create: (_) => FirearmRepositorySqlite(database),
        ),
        Provider<LoadRecipeRepository>(
          create: (_) => LoadRecipeRepositorySqlite(database),
        ),
        Provider<RangeResultRepository>(
          create: (_) => RangeResultRepositorySqlite(database),
        ),
        Provider<TargetPhotoRepository>(
          create: (_) => TargetPhotoRepositorySqlite(database),
        ),
        ProxyProvider3<LoadRecipeRepository, RangeResultRepository,
            TargetPhotoRepository, ExportService>(
          update: (_, loadRepo, rangeRepo, photoRepo, previous) =>
              previous ?? ExportService(loadRepo, rangeRepo, photoRepo),
        ),
        Provider<InventoryRepository>(
          create: (_) => InventoryRepositorySqlite(database),
        ),
        Provider<SettingsRepository>(
          create: (_) => SettingsRepositorySqlite(database),
        ),
        ProxyProvider<SettingsRepository, PurchaseService>(
          update: (_, settings, previous) {
            final service = previous ?? PurchaseService(settings);
            if (previous == null) {
              service.init();
            }
            return service;
          },
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'Load Intel',
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}

