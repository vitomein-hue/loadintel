import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:loadintel/features/inventory/inventory_screen.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/services/backup_service.dart';
import 'package:loadintel/services/export_service.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
    final box = context.findRenderObject() as RenderBox?;
    try {
      final result = await Share.shareXFiles(
        [XFile(path)],
        subject: 'Load Intel Backup',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
      if (result.status == ShareResultStatus.unavailable && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing is unavailable on this device.')),
        );
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share backup right now.')),
      );
    }
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

  Future<void> _showBackupRestoreDialog() async {
    final parentContext = context;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Backup/Restore'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _exportBackup(parentContext);
            },
            child: Row(
              children: const [
                Icon(Icons.file_download),
                SizedBox(width: 12),
                Text('Export Backup'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _importBackup(parentContext);
            },
            child: Row(
              children: const [
                Icon(Icons.file_upload),
                SizedBox(width: 12),
                Text('Import Backup'),
              ],
            ),
          ),
        ],
      ),
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
              title: const Text('Backup/Restore'),
              subtitle: const Text('Export or import a JSON backup.'),
              trailing: const Icon(Icons.backup),
              onTap: _showBackupRestoreDialog,
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
