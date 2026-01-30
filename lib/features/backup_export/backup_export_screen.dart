import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loadintel/features/inventory/inventory_screen.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/services/backup_service.dart';
import 'package:loadintel/services/export_service.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:provider/provider.dart';

class BackupExportScreen extends StatefulWidget {
  const BackupExportScreen({super.key});

  @override
  State<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends State<BackupExportScreen> {
  ProEntitlementOverride _proOverride = ProEntitlementOverride.auto;
  bool _overrideLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProOverride();
  }

  Future<void> _loadProOverride() async {
    final settings = context.read<SettingsRepository>();
    final value = await settings.getProEntitlementOverride();
    if (!mounted) {
      return;
    }
    setState(() {
      _proOverride = value;
      _overrideLoaded = true;
    });
  }

  Future<void> _setProOverride(ProEntitlementOverride value) async {
    setState(() {
      _proOverride = value;
    });
    await context.read<SettingsRepository>().setProEntitlementOverride(value);
    await context.read<PurchaseService>().refreshEntitlement();
  }

  Future<void> _exportBackup(BuildContext context) async {
    final service = context.read<BackupService>();
    final path = await service.exportBackup();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup saved: $path')),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) {
      return;
    }
    final filePath = result.files.single.path!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace all local data?'),
        content: const Text('Importing will overwrite all current data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final service = context.read<BackupService>();
    await service.importBackup(filePath);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup imported.')),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final service = context.read<ExportService>();
    final files = await service.exportCsv();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported: ${files.join(', ')}')),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final service = context.read<ExportService>();
    final files = await service.exportPdfReports();
    if (!context.mounted) {
      return;
    }
    final location =
        files.isNotEmpty ? files.first : 'App documents/exports';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF reports saved (${files.length}). $location'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Export'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LegalDisclaimerScreen()),
              );
            },
            child: Text(
              'Legal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Inventory'),
              subtitle: const Text('Manage brass, bullets, powder, and primers.'),
              trailing: const Icon(Icons.inventory_2),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Export Backup'),
              subtitle: const Text('Create a JSON backup of local data.'),
              trailing: const Icon(Icons.file_download),
              onTap: () => _exportBackup(context),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Import Backup'),
              subtitle: const Text('Replace local data with a backup file.'),
              trailing: const Icon(Icons.file_upload),
              onTap: () => _importBackup(context),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Export CSV'),
              subtitle: const Text('Generate loads.csv and results.csv.'),
              trailing: const Icon(Icons.table_view),
              onTap: () => _exportCsv(context),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Export PDF Reports'),
              subtitle: const Text('Generate per-load PDF reports.'),
              trailing: const Icon(Icons.picture_as_pdf),
              onTap: () => _exportPdf(context),
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Pro gate (dev)'),
                subtitle: const Text('Auto uses purchases; force on/off to test.'),
                trailing: _overrideLoaded
                    ? DropdownButtonHideUnderline(
                        child: DropdownButton<ProEntitlementOverride>(
                          value: _proOverride,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            _setProOverride(value);
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ProEntitlementOverride.auto,
                              child: Text('Auto'),
                            ),
                            DropdownMenuItem(
                              value: ProEntitlementOverride.forceOn,
                              child: Text('Force On'),
                            ),
                            DropdownMenuItem(
                              value: ProEntitlementOverride.forceOff,
                              child: Text('Force Off'),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LegalDisclaimerScreen extends StatelessWidget {
  const LegalDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Legal & Safety Disclaimer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Load Intel is a data logging and reference tool only. It does not provide load data, '
            'reloading recipes, or ballistic recommendations.',
          ),
          SizedBox(height: 12),
          Text(
            'All ammunition reloading involves risk. The user is solely responsible for verifying '
            'the safety and suitability of all load data entered into this app. Always follow '
            'published reloading manuals, component manufacturer guidelines, and safe reloading '
            'practices.',
          ),
          SizedBox(height: 12),
          Text(
            'Load Intel does not validate powder charges, bullet seating depth, pressure limits, '
            'or firearm compatibility. Data stored in this app is entered by the user and may '
            'contain errors.',
          ),
          SizedBox(height: 12),
          Text('By using this app, you acknowledge that:'),
          SizedBox(height: 8),
          Text('You are responsible for the safe use of all firearms and ammunition.'),
          SizedBox(height: 8),
          Text(
            'You understand that improper or unsafe reloading can result in injury, death, or '
            'property damage.',
          ),
          SizedBox(height: 8),
          Text(
            'Load Intel and its developers are not liable for any harm resulting from the use '
            'or misuse of this application or any data stored within it.',
          ),
          SizedBox(height: 8),
          Text(
            'This app is not intended to replace professional training, manufacturer specifications, '
            'or published reloading manuals.',
          ),
          SizedBox(height: 12),
          Text('Use responsibly.'),
        ],
      ),
    );
  }
}
