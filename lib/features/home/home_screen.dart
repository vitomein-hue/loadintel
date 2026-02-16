import 'package:flutter/material.dart';
import 'package:loadintel/core/theme/app_colors.dart';
import 'package:loadintel/features/backup_export/backup_export_screen.dart';
import 'package:loadintel/features/build_load/build_load_screen.dart';
import 'package:loadintel/features/inventory/inventory_screen.dart';
import 'package:loadintel/features/load_history/load_history_screen.dart';
import 'package:loadintel/features/range_test/range_test_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: TextButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            );
          },
          icon: const Icon(Icons.inventory_2),
          label: const Text('Inventory'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupExportScreen()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage('assets/splash.png'),
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _BetaBanner(),
                const SizedBox(height: 12),
                const Spacer(),
                _HomeNavButton(
                  label: 'Build Load',
                  icon: Icons.edit_note,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BuildLoadScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _HomeNavButton(
                  label: 'Range Test',
                  icon: Icons.my_location,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RangeTestScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _HomeNavButton(
                  label: 'Load History',
                  icon: Icons.history,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoadHistoryScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BetaBanner extends StatelessWidget {
  const _BetaBanner();

  static final Future<PackageInfo> _infoFuture = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _infoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final versionText =
            info == null ? 'v--' : 'v${info.version} (${info.buildNumber})';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.danger),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.new_releases, color: AppColors.danger),
              const SizedBox(width: 8),
              const Text(
                'BETA',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                versionText,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeNavButton extends StatelessWidget {
  const _HomeNavButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.burntCopper,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
