import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loadintel/domain/models/load_with_best_result.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/features/inventory/inventory_screen.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/services/backup_service.dart';
import 'package:loadintel/services/export_service.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

enum _ShareExportFormat { csv, xlsx, pdf, txt, png }

class BackupExportScreen extends StatefulWidget {
  const BackupExportScreen({super.key});

  @override
  State<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends State<BackupExportScreen> {
  ProEntitlementOverride _proOverride = ProEntitlementOverride.auto;
  bool _overrideLoaded = false;
  bool _isExporting = false;

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

  String _proOverrideLabel(ProEntitlementOverride value) {
    switch (value) {
      case ProEntitlementOverride.auto:
        return 'Auto (use entitlement)';
      case ProEntitlementOverride.forceOn:
        return 'Force On (Pro)';
      case ProEntitlementOverride.forceOff:
        return 'Force Off (Free)';
    }
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

  Future<void> _showShareLoadDataSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Share load data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                if (_isExporting) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 8),
                _ShareOptionTile(
                  label: 'Export CSV',
                  icon: Icons.table_view,
                  enabled: !_isExporting,
                  onTap: () => _handleShareExport(
                    sheetContext,
                    setSheetState,
                    _ShareExportFormat.csv,
                  ),
                ),
                _ShareOptionTile(
                  label: 'Export XLSX',
                  icon: Icons.grid_on,
                  enabled: !_isExporting,
                  onTap: () => _handleShareExport(
                    sheetContext,
                    setSheetState,
                    _ShareExportFormat.xlsx,
                  ),
                ),
                _ShareOptionTile(
                  label: 'Export PDF',
                  icon: Icons.picture_as_pdf,
                  enabled: !_isExporting,
                  onTap: () => _handleShareExport(
                    sheetContext,
                    setSheetState,
                    _ShareExportFormat.pdf,
                  ),
                ),
                _ShareOptionTile(
                  label: 'Export TXT',
                  icon: Icons.text_snippet,
                  enabled: !_isExporting,
                  onTap: () => _handleShareExport(
                    sheetContext,
                    setSheetState,
                    _ShareExportFormat.txt,
                  ),
                ),
                _ShareOptionTile(
                  label: 'Export PNG',
                  icon: Icons.image,
                  enabled: !_isExporting,
                  onTap: () => _handleShareExport(
                    sheetContext,
                    setSheetState,
                    _ShareExportFormat.png,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleShareExport(
    BuildContext sheetContext,
    StateSetter setSheetState,
    _ShareExportFormat format,
  ) async {
    if (_isExporting) {
      return;
    }
    final selected = await _pickTestedLoad(sheetContext);
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _isExporting = true;
    });
    setSheetState(() {});
    try {
      final exportService = context.read<ExportService>();
      final xFile = await _exportSingleLoad(
        context: context,
        exportService: exportService,
        selected: selected,
        format: format,
      );
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [xFile],
        subject: 'Load Intel ${_formatLabel(format)} Export',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export ready to share')),
      );
    } catch (error) {
      debugPrint('Export failed: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        setSheetState(() {});
      }
      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }
    }
  }

  Future<XFile> _exportSingleLoad({
    required BuildContext context,
    required ExportService exportService,
    required LoadWithBestResult selected,
    required _ShareExportFormat format,
  }) async {
    switch (format) {
      case _ShareExportFormat.csv:
        return exportService.exportSingleLoadCsv(selected.recipe);
      case _ShareExportFormat.xlsx:
        return exportService.exportSingleLoadXlsx(selected.recipe);
      case _ShareExportFormat.pdf:
        return exportService.exportSingleLoadPdf(selected.recipe);
      case _ShareExportFormat.txt:
        return exportService.exportSingleLoadTxt(selected.recipe);
      case _ShareExportFormat.png:
        return exportService.saveSingleLoadPng(
          context: context,
          load: selected.recipe,
        );
    }
  }

  Future<LoadWithBestResult?> _pickTestedLoad(BuildContext context) async {
    final loads = await context.read<LoadRecipeRepository>().listTestedLoads();
    if (loads.isEmpty) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tested loads available.')),
      );
      return null;
    }
    return showDialog<LoadWithBestResult>(
      context: context,
      builder: (dialogContext) {
        var query = '';
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final filtered = _filterLoads(loads, query);
            return AlertDialog(
              title: const Text('Select load'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          query = value.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matches.'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final entry = filtered[index];
                                return ListTile(
                                  title: Text(_loadTitle(entry)),
                                  subtitle: Text(_loadSubtitle(entry)),
                                  onTap: () => Navigator.of(dialogContext).pop(entry),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<LoadWithBestResult> _filterLoads(
    List<LoadWithBestResult> loads,
    String query,
  ) {
    if (query.isEmpty) {
      return loads;
    }
    final lower = query.toLowerCase();
    return loads.where((entry) {
      final recipe = entry.recipe;
      final haystack = [
        recipe.recipeName,
        recipe.cartridge,
        recipe.powder,
        recipe.bulletBrand,
        recipe.bulletType,
        recipe.brass,
        recipe.primer,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(lower);
    }).toList();
  }

  String _loadTitle(LoadWithBestResult entry) {
    final recipe = entry.recipe;
    return '${recipe.cartridge} - ${recipe.recipeName}';
  }

  String _loadSubtitle(LoadWithBestResult entry) {
    final recipe = entry.recipe;
    final bulletParts = <String>[
      if (recipe.bulletBrand != null && recipe.bulletBrand!.isNotEmpty)
        recipe.bulletBrand!,
      if (recipe.bulletWeightGr != null) '${recipe.bulletWeightGr} gr',
      if (recipe.bulletType != null && recipe.bulletType!.isNotEmpty)
        recipe.bulletType!,
    ];
    final bullet = bulletParts.isEmpty ? '-' : bulletParts.join(' ');
    final powder = '${recipe.powder} ${recipe.powderChargeGr} gr';
    final best = entry.bestResult;
    final bestGroup = best == null ? '-' : '${best.groupSizeIn.toStringAsFixed(2)} in';
    final testedAt =
        best == null ? '-' : best.testedAt.toLocal().toString().split(' ').first;
    return '$bullet | $powder | Best $bestGroup | $testedAt';
  }

  String _formatLabel(_ShareExportFormat format) {
    switch (format) {
      case _ShareExportFormat.csv:
        return 'CSV';
      case _ShareExportFormat.xlsx:
        return 'XLSX';
      case _ShareExportFormat.pdf:
        return 'PDF';
      case _ShareExportFormat.txt:
        return 'TXT';
      case _ShareExportFormat.png:
        return 'PNG';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
              title: const Text('Share load data'),
              subtitle: const Text('Export and share a tested load.'),
              trailing: const Icon(Icons.share),
              onTap: _showShareLoadDataSheet,
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProEntitlementOverride>(
                      value: _proOverride,
                      decoration: const InputDecoration(
                        labelText: 'Pro entitlement (debug)',
                      ),
                      items: ProEntitlementOverride.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_proOverrideLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: _overrideLoaded
                          ? (value) {
                              if (value == null) {
                                return;
                              }
                              _setProOverride(value);
                            }
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Debug builds only. PRO_OVERRIDE dart-define overrides this.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  const _ShareOptionTile({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      title: Text(label),
      leading: Icon(icon),
      trailing: enabled ? const Icon(Icons.chevron_right) : null,
      onTap: enabled ? onTap : null,
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
