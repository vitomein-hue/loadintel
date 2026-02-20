import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'package:loadintel/features/onboarding/intro_screen.dart';
import 'package:loadintel/features/trial/trial_paywall.dart';
import 'package:loadintel/features/trial/trial_dialog.dart';
import 'package:loadintel/services/backup_service.dart';
import 'package:loadintel/services/export_service.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:loadintel/services/trial_service.dart';
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
        Provider<InventoryRepository>(
          create: (_) => InventoryRepositorySqlite(database),
        ),
        Provider<SettingsRepository>(
          create: (_) => SettingsRepositorySqlite(database),
        ),
        ProxyProvider4<
          LoadRecipeRepository,
          RangeResultRepository,
          TargetPhotoRepository,
          SettingsRepository,
          ExportService
        >(
          update: (_, loadRepo, rangeRepo, photoRepo, settingsRepo, previous) =>
              previous ??
              ExportService(loadRepo, rangeRepo, photoRepo, settingsRepo),
        ),
        ChangeNotifierProxyProvider<SettingsRepository, PurchaseService>(
          create: (context) {
            final service = PurchaseService(context.read<SettingsRepository>());
            unawaited(
              service.init().timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  if (kDebugMode) {
                    debugPrint('PurchaseService init timeout');
                  }
                },
              ),
            );
            return service;
          },
          update: (_, settingsRepo, previous) => previous!,
        ),
        ChangeNotifierProxyProvider2<
          SettingsRepository,
          PurchaseService,
          TrialService
        >(
          create: (context) {
            final service = TrialService(
              context.read<SettingsRepository>(),
              context.read<PurchaseService>(),
            );
            unawaited(
              service.init().timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  if (kDebugMode) {
                    debugPrint('TrialService init timeout');
                  }
                },
              ),
            );
            return service;
          },
          update: (_, settingsRepo, purchaseService, previous) => previous!,
        ),
      ],
      child: MaterialApp(
        title: 'Load Intel',
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        home: const _TrialAwareHome(),
      ),
    );
  }
}

class _TrialAwareHome extends StatefulWidget {
  const _TrialAwareHome();

  @override
  State<_TrialAwareHome> createState() => _TrialAwareHomeState();
}

class _TrialAwareHomeState extends State<_TrialAwareHome> {
  bool _hasShownDialog = false;
  bool _isCheckingIntro = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final purchaseService = context.read<PurchaseService>();
      await purchaseService.initializationDone.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('PurchaseService init timeout');
          }
        },
      );
      if (!mounted) {
        return;
      }
      _checkIntroStatus();
    });
  }

  Future<void> _checkIntroStatus() async {
    final settingsRepo = context.read<SettingsRepository>();
    final purchaseService = context.read<PurchaseService>();
    final trialService = context.read<TrialService>();

    // Skip intro only when user has a real entitlement
    final hasLifetime = purchaseService.hasLifetimeAccess();
    if (!trialService.isInitialized) {
      await trialService.init().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('TrialService init timeout');
          }
        },
      );
    }
    final hadTrial = trialService.hasTrialStarted();

    if (!hasLifetime && !hadTrial) {
      final autoStartDone =
          await settingsRepo.getBool('trial_autostart_done') ?? false;
      if (!autoStartDone) {
        try {
          await trialService.startTrialAutomatically().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              if (kDebugMode) {
                debugPrint('TrialService auto-start timeout');
              }
            },
          );
        } finally {
          await settingsRepo.setBool('trial_autostart_done', true);
        }
      }
    }

    final shouldSkip = hasLifetime || hadTrial;

    setState(() {
      _isCheckingIntro = false;
    });

    if (!shouldSkip) {
      // Wait for user to complete intro
      if (mounted) {
        final completed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const IntroScreen(),
            fullscreenDialog: true,
          ),
        );

        // Mark intro as completed
        if (completed == true) {
          await settingsRepo.setBool('intro_completed', true);
          if (mounted) {
            _checkTrialStatus();
          }
        } else if (mounted) {
          setState(() {
            _isCheckingIntro = true;
          });
          _checkIntroStatus();
        }
      }
    } else {
      _checkTrialStatus();
    }
  }

  Future<void> _checkTrialStatus() async {
    if (_hasShownDialog) return;

    final purchaseService = context.read<PurchaseService>();
    final trialService = context.read<TrialService>();

    // If user has lifetime access, no trial restrictions
    if (purchaseService.hasLifetimeAccess()) {
      return;
    }

    // Trial is tracked locally via stored start date

    // Show appropriate dialog based on trial phase
    if (!mounted) return;

    if (trialService.shouldShowLastDayDialog()) {
      _hasShownDialog = true;
      await TrialDialog.showLastDayDialog(context);
    } else if (trialService.shouldShowGracePeriodDialog()) {
      _hasShownDialog = true;
      await TrialDialog.showGracePeriodDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking intro status
    if (_isCheckingIntro) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final purchaseService = context.watch<PurchaseService>();
    final trialService = context.watch<TrialService>();

    // If user has lifetime access, show normal app
    if (purchaseService.hasLifetimeAccess()) {
      return const HomeScreen();
    }

    // If trial expired, show hard block
    if (trialService.shouldShowHardBlock()) {
      return const TrialPaywall();
    }

    // Otherwise show normal app
    return const HomeScreen();
  }
}
