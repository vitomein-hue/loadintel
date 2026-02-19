import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:loadintel/core/theme/app_colors.dart';
import 'package:loadintel/core/widgets/keyboard_safe_page.dart';
import 'package:loadintel/domain/models/firearm.dart';
import 'package:loadintel/domain/models/inventory_item.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/repositories/firearm_repository.dart';
import 'package:loadintel/domain/repositories/inventory_repository.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/features/trial/trial_banner.dart';
import 'package:loadintel/services/trial_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class BuildLoadScreen extends StatefulWidget {
  const BuildLoadScreen({super.key, this.recipe, this.isDuplicate = false});

  final LoadRecipe? recipe;
  final bool isDuplicate;

  @override
  State<BuildLoadScreen> createState() => _BuildLoadScreenState();
}

class _BuildLoadScreenState extends State<BuildLoadScreen> {
  static const String _customOptionPrefix = '__custom_option__::';
  static const String _inventoryAddedPrefix = '__inventory_added__::';

  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _recipeNameController;
  late final TextEditingController _cartridgeController;
  late final TextEditingController _bulletBrandController;
  late final TextEditingController _bulletWeightController;
  late final TextEditingController _bulletDiameterController;
  late final TextEditingController _bulletTypeController;
  late final TextEditingController _caseResizeController;
  late final TextEditingController _gasCheckMaterialController;
  late final TextEditingController _gasCheckInstallMethodController;
  late final TextEditingController _bulletCoatingController;
  late final TextEditingController _brassController;
  late final TextEditingController _brassTrimLengthController;
  late final TextEditingController _annealingTimeController;
  late final TextEditingController _primerController;
  late final TextEditingController _powderController;
  late final TextEditingController _powderChargeController;
  late final TextEditingController _coalController;
  late final TextEditingController _baseToOgiveController;
  late final TextEditingController _seatingDepthController;
  late final TextEditingController _notesController;
  late final TextEditingController _shotgunHullController;
  late final TextEditingController _shotgunPrimerController;
  late final TextEditingController _shotgunPowderController;
  late final TextEditingController _shotgunPowderChargeController;
  late final TextEditingController _shotgunWadController;
  late final TextEditingController _shotgunShotWeightController;
  late final TextEditingController _shotgunShotSizeController;
  late final TextEditingController _shotgunDramEquivalentController;
  late final TextEditingController _muzzleloaderCaliberController;
  late final TextEditingController _muzzleloaderPowderChargeController;
  late final TextEditingController _projectileSizeWeightController;
  late final TextEditingController _patchMaterialController;
  late final TextEditingController _patchThicknessController;
  late final TextEditingController _patchLubeController;
  late final TextEditingController _sabotTypeController;

  String? _selectedFirearmId;
  String? _selectedBrass;
  String? _selectedBullet;
  String? _selectedPowder;
  String? _selectedPrimer;
  String? _selectedCaseResize;
  String? _selectedGasCheckMaterial;
  String? _selectedGasCheckInstallMethod;
  String? _selectedBulletCoating;
  String? _selectedWad;
  String? _selectedGauge;
  String? _selectedShellLength;
  String? _selectedShotType;
  String? _selectedCrimpType;
  String? _selectedIgnitionType;
  String? _selectedMuzzleloaderPowderType;
  String? _selectedPowderGranulation;
  String? _selectedProjectileType;
  bool _cleanedBetweenShots = false;
  LoadType _selectedLoadType = LoadType.rifle;

  bool _isDangerous = false;
  DateTime? _dangerConfirmedAt;
  late Future<_BuildLoadData> _dataFuture;

  bool _isEditing = false;
  String? _editingRecipeId;
  DateTime? _editingCreatedAt;
  bool _isDuplicateSaving = false;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    _isEditing = recipe != null && !widget.isDuplicate;
    _editingRecipeId = _isEditing ? recipe!.id : null;
    _editingCreatedAt = _isEditing ? recipe!.createdAt : null;
    _recipeNameController = TextEditingController(
      text: recipe?.recipeName ?? '',
    );
    _cartridgeController = TextEditingController(text: recipe?.cartridge ?? '');
    _bulletBrandController = TextEditingController(
      text: recipe?.bulletBrand ?? '',
    );
    _bulletWeightController = TextEditingController(
      text: recipe?.bulletWeightGr?.toString() ?? '',
    );
    _bulletDiameterController = TextEditingController(
      text: recipe?.bulletDiameter?.toString() ?? '',
    );
    _bulletTypeController = TextEditingController(
      text: recipe?.bulletType ?? '',
    );
    _caseResizeController = TextEditingController(
      text: recipe?.caseResize ?? '',
    );
    _gasCheckMaterialController = TextEditingController(
      text: recipe?.gasCheckMaterial ?? '',
    );
    _gasCheckInstallMethodController = TextEditingController(
      text: recipe?.gasCheckInstallMethod ?? '',
    );
    _bulletCoatingController = TextEditingController(
      text: recipe?.bulletCoating ?? '',
    );
    _brassController = TextEditingController(text: recipe?.brass ?? '');
    _brassTrimLengthController = TextEditingController(
      text: recipe?.brassTrimLength?.toString() ?? '',
    );
    _annealingTimeController = TextEditingController(
      text: recipe?.annealingTimeSec?.toString() ?? '',
    );
    _primerController = TextEditingController(text: recipe?.primer ?? '');
    _powderController = TextEditingController(text: recipe?.powder ?? '');
    _powderChargeController = TextEditingController(
      text: recipe?.powderChargeGr.toString() ?? '',
    );
    _coalController = TextEditingController(
      text: recipe?.coal?.toString() ?? '',
    );
    _baseToOgiveController = TextEditingController(
      text: recipe?.baseToOgive?.toString() ?? '',
    );
    _seatingDepthController = TextEditingController(
      text: recipe?.seatingDepth?.toString() ?? '',
    );
    _notesController = TextEditingController(text: recipe?.notes ?? '');
    _shotgunHullController = TextEditingController(text: recipe?.hull ?? '');
    _shotgunPrimerController = TextEditingController(
      text: recipe?.shotgunPrimer ?? '',
    );
    _shotgunPowderController = TextEditingController(
      text: recipe?.shotgunPowder ?? '',
    );
    _shotgunPowderChargeController = TextEditingController(
      text: recipe?.shotgunPowderCharge?.toString() ?? '',
    );
    _shotgunWadController = TextEditingController(text: recipe?.wad ?? '');
    _shotgunShotWeightController = TextEditingController(
      text: recipe?.shotWeight ?? '',
    );
    _shotgunShotSizeController = TextEditingController(
      text: recipe?.shotSize ?? '',
    );
    _shotgunDramEquivalentController = TextEditingController(
      text: recipe?.dramEquivalent?.toString() ?? '',
    );
    _muzzleloaderCaliberController = TextEditingController(
      text: recipe?.muzzleloaderCaliber ?? '',
    );
    _muzzleloaderPowderChargeController = TextEditingController(
      text: recipe?.muzzleloaderPowderCharge?.toString() ?? '',
    );
    _projectileSizeWeightController = TextEditingController(
      text: recipe?.projectileSizeWeight ?? '',
    );
    _patchMaterialController = TextEditingController(
      text: recipe?.patchMaterial ?? '',
    );
    _patchThicknessController = TextEditingController(
      text: recipe?.patchThickness ?? '',
    );
    _patchLubeController = TextEditingController(text: recipe?.patchLube ?? '');
    _sabotTypeController = TextEditingController(text: recipe?.sabotType ?? '');

    _selectedFirearmId = recipe?.firearmId;
    _selectedBrass = recipe?.brass;
    _selectedBullet = recipe?.bulletBrand;
    _selectedPowder = recipe?.powder;
    _selectedPrimer = recipe?.primer;
    _selectedCaseResize = recipe?.caseResize;
    _selectedGasCheckMaterial = recipe?.gasCheckMaterial;
    _selectedGasCheckInstallMethod = recipe?.gasCheckInstallMethod;
    _selectedBulletCoating = recipe?.bulletCoating;
    _selectedWad = recipe?.wad;
    _selectedGauge = recipe?.gauge;
    _selectedShellLength = recipe?.shellLength;
    _selectedShotType = recipe?.shotType;
    _selectedCrimpType = recipe?.crimpType;
    _selectedIgnitionType = recipe?.ignitionType;
    _selectedMuzzleloaderPowderType = recipe?.muzzleloaderPowderType;
    _selectedPowderGranulation = recipe?.powderGranulation;
    _selectedProjectileType = recipe?.projectileType;
    _cleanedBetweenShots = recipe?.cleanedBetweenShots ?? false;
    _selectedLoadType = recipe?.loadType ?? LoadType.rifle;

    _isDangerous = recipe?.isDangerous ?? false;
    _dangerConfirmedAt = recipe?.dangerConfirmedAt;

    _dataFuture = _loadData();
  }

  void _applyRecipeToForm(LoadRecipe recipe) {
    _recipeNameController.text = recipe.recipeName;
    _cartridgeController.text = recipe.cartridge;
    _bulletBrandController.text = recipe.bulletBrand ?? '';
    _bulletWeightController.text = recipe.bulletWeightGr?.toString() ?? '';
    _bulletDiameterController.text = recipe.bulletDiameter?.toString() ?? '';
    _bulletTypeController.text = recipe.bulletType ?? '';
    _caseResizeController.text = recipe.caseResize ?? '';
    _gasCheckMaterialController.text = recipe.gasCheckMaterial ?? '';
    _gasCheckInstallMethodController.text = recipe.gasCheckInstallMethod ?? '';
    _bulletCoatingController.text = recipe.bulletCoating ?? '';
    _brassController.text = recipe.brass ?? '';
    _brassTrimLengthController.text = recipe.brassTrimLength?.toString() ?? '';
    _annealingTimeController.text = recipe.annealingTimeSec?.toString() ?? '';
    _primerController.text = recipe.primer ?? '';
    _powderController.text = recipe.powder;
    _powderChargeController.text = recipe.powderChargeGr.toString();
    _coalController.text = recipe.coal?.toString() ?? '';
    _baseToOgiveController.text = recipe.baseToOgive?.toString() ?? '';
    _seatingDepthController.text = recipe.seatingDepth?.toString() ?? '';
    _notesController.text = recipe.notes ?? '';
    _shotgunHullController.text = recipe.hull ?? '';
    _shotgunPrimerController.text = recipe.shotgunPrimer ?? '';
    _shotgunPowderController.text = recipe.shotgunPowder ?? '';
    _shotgunPowderChargeController.text =
        recipe.shotgunPowderCharge?.toString() ?? '';
    _shotgunWadController.text = recipe.wad ?? '';
    _shotgunShotWeightController.text = recipe.shotWeight ?? '';
    _shotgunShotSizeController.text = recipe.shotSize ?? '';
    _shotgunDramEquivalentController.text =
        recipe.dramEquivalent?.toString() ?? '';
    _muzzleloaderCaliberController.text = recipe.muzzleloaderCaliber ?? '';
    _muzzleloaderPowderChargeController.text =
        recipe.muzzleloaderPowderCharge?.toString() ?? '';
    _projectileSizeWeightController.text = recipe.projectileSizeWeight ?? '';
    _patchMaterialController.text = recipe.patchMaterial ?? '';
    _patchThicknessController.text = recipe.patchThickness ?? '';
    _patchLubeController.text = recipe.patchLube ?? '';
    _sabotTypeController.text = recipe.sabotType ?? '';

    _selectedFirearmId = recipe.firearmId;
    _selectedBrass = recipe.brass;
    _selectedBullet = recipe.bulletBrand;
    _selectedPowder = recipe.powder;
    _selectedPrimer = recipe.primer;
    _selectedCaseResize = recipe.caseResize;
    _selectedGasCheckMaterial = recipe.gasCheckMaterial;
    _selectedGasCheckInstallMethod = recipe.gasCheckInstallMethod;
    _selectedBulletCoating = recipe.bulletCoating;
    _selectedWad = recipe.wad;
    _selectedGauge = recipe.gauge;
    _selectedShellLength = recipe.shellLength;
    _selectedShotType = recipe.shotType;
    _selectedCrimpType = recipe.crimpType;
    _selectedIgnitionType = recipe.ignitionType;
    _selectedMuzzleloaderPowderType = recipe.muzzleloaderPowderType;
    _selectedPowderGranulation = recipe.powderGranulation;
    _selectedProjectileType = recipe.projectileType;
    _cleanedBetweenShots = recipe.cleanedBetweenShots ?? false;
    _selectedLoadType = recipe.loadType;

    _isDangerous = recipe.isDangerous;
    _dangerConfirmedAt = recipe.dangerConfirmedAt;
  }

  @override
  void dispose() {
    _recipeNameController.dispose();
    _cartridgeController.dispose();
    _bulletBrandController.dispose();
    _bulletWeightController.dispose();
    _bulletDiameterController.dispose();
    _bulletTypeController.dispose();
    _caseResizeController.dispose();
    _gasCheckMaterialController.dispose();
    _gasCheckInstallMethodController.dispose();
    _bulletCoatingController.dispose();
    _brassController.dispose();
    _brassTrimLengthController.dispose();
    _annealingTimeController.dispose();
    _primerController.dispose();
    _powderController.dispose();
    _powderChargeController.dispose();
    _coalController.dispose();
    _baseToOgiveController.dispose();
    _seatingDepthController.dispose();
    _notesController.dispose();
    _shotgunHullController.dispose();
    _shotgunPrimerController.dispose();
    _shotgunPowderController.dispose();
    _shotgunPowderChargeController.dispose();
    _shotgunWadController.dispose();
    _shotgunShotWeightController.dispose();
    _shotgunShotSizeController.dispose();
    _shotgunDramEquivalentController.dispose();
    _muzzleloaderCaliberController.dispose();
    _muzzleloaderPowderChargeController.dispose();
    _projectileSizeWeightController.dispose();
    _patchMaterialController.dispose();
    _patchThicknessController.dispose();
    _patchLubeController.dispose();
    _sabotTypeController.dispose();
    super.dispose();
  }

  Future<_BuildLoadData> _loadData() async {
    final firearmRepo = context.read<FirearmRepository>();
    final inventoryRepo = context.read<InventoryRepository>();
    final settingsRepo = context.read<SettingsRepository>();
    final firearms = await firearmRepo.listFirearms();
    final items = await inventoryRepo.listItems();
    final inventoryByType = <String, List<InventoryItem>>{};
    for (final item in items) {
      inventoryByType.putIfAbsent(item.type, () => []).add(item);
    }
    for (final list in inventoryByType.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    final customCaseResize = await _loadCustomOptions(
      settingsRepo,
      SettingsKeys.caseResizeOptions,
    );
    final customGasCheckMaterial = await _loadCustomOptions(
      settingsRepo,
      SettingsKeys.gasCheckMaterialOptions,
    );
    final customGasCheckInstallMethod = await _loadCustomOptions(
      settingsRepo,
      SettingsKeys.gasCheckInstallMethodOptions,
    );
    final customBulletCoating = await _loadCustomOptions(
      settingsRepo,
      SettingsKeys.bulletCoatingOptions,
    );
    return _BuildLoadData(
      firearms: firearms,
      inventoryByType: inventoryByType,
      customCaseResize: customCaseResize,
      customGasCheckMaterial: customGasCheckMaterial,
      customGasCheckInstallMethod: customGasCheckInstallMethod,
      customBulletCoating: customBulletCoating,
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<void> _addFirearm() async {
    final repo = context.read<FirearmRepository>();
    final created = await showDialog<Firearm>(
      context: context,
      builder: (context) => const _AddFirearmDialog(),
    );
    if (created == null) {
      return;
    }
    await repo.upsertFirearm(created);
    await _refreshData();
    setState(() {
      _selectedFirearmId = created.id;
    });
  }

  String _displayInventoryValue(String? value, List<InventoryItem> items) {
    if (value == null || value.isEmpty) {
      return '';
    }
    final exists = items.any((item) => item.name == value);
    return exists ? value : '$value (missing)';
  }

  String? _optionalText(TextEditingController controller) {
    final trimmed = controller.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _buildShotgunCartridge() {
    final gauge = _selectedGauge ?? '';
    final shell = _selectedShellLength ?? '';
    final parts = [gauge, shell].where((value) => value.isNotEmpty).toList();
    return parts.join(' ');
  }

  void _syncInventoryControllers(
    Map<String, List<InventoryItem>> inventoryByType,
  ) {
    _bulletBrandController.text = _displayInventoryValue(
      _selectedBullet,
      inventoryByType['bullets'] ?? [],
    );
    _brassController.text = _displayInventoryValue(
      _selectedBrass,
      inventoryByType['brass'] ?? [],
    );
    _primerController.text = _displayInventoryValue(
      _selectedPrimer,
      inventoryByType['primers'] ?? [],
    );
    _powderController.text = _displayInventoryValue(
      _selectedPowder,
      inventoryByType['powder'] ?? [],
    );
    _shotgunWadController.text = _displayInventoryValue(
      _selectedWad,
      inventoryByType['wads'] ?? [],
    );
  }

  Future<List<String>> _loadCustomOptions(
    SettingsRepository settingsRepo,
    String key,
  ) async {
    final raw = await settingsRepo.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<String>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> _pickCustomOption({
    required String label,
    required String prefsKey,
    required List<String> predefinedOptions,
    required List<String> customOptions,
  }) async {
    final options = <String>[...predefinedOptions, ...customOptions];

    final controller = TextEditingController();
    bool isAdding = false;
    String? errorText;
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (!isAdding)
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ...options.map(
                              (option) => ListTile(
                                title: Text(option),
                                onTap: () => Navigator.of(context).pop(option),
                              ),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('+ Add...'),
                              onTap: () => setSheetState(() {
                                isAdding = true;
                                errorText = null;
                                controller.clear();
                              }),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: label,
                              errorText: errorText,
                            ),
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setSheetState(() {
                                    isAdding = false;
                                    errorText = null;
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  final trimmed = controller.text.trim();
                                  if (trimmed.isEmpty) {
                                    setSheetState(() {
                                      errorText = 'Enter a value';
                                    });
                                    return;
                                  }
                                  final existing = options.firstWhere(
                                    (option) =>
                                        option.toLowerCase() ==
                                        trimmed.toLowerCase(),
                                    orElse: () => '',
                                  );
                                  if (existing.isNotEmpty) {
                                    Navigator.of(context).pop(existing);
                                    return;
                                  }
                                  Navigator.of(
                                    context,
                                  ).pop('$_customOptionPrefix$trimmed');
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    controller.dispose();
    if (!mounted || result == null) {
      return null;
    }
    if (result.startsWith(_customOptionPrefix)) {
      final trimmed = result.substring(_customOptionPrefix.length);
      final updated = [...customOptions, trimmed];
      await context.read<SettingsRepository>().setString(
        prefsKey,
        jsonEncode(updated),
      );
      debugPrint('Saved custom option [$prefsKey]: $trimmed');
      await _refreshData();
      return trimmed;
    }
    return result;
  }

  Future<String?> _pickInventoryItem({
    required String title,
    required List<InventoryItem> items,
    required String type,
    required bool allowClear,
  }) async {
    final addController = TextEditingController();
    String query = '';
    bool isAdding = false;
    String? errorText;
    final label = _inventoryLabelForType(type);
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(
            top: 60,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.65,
            ),
            child: SafeArea(
              child: StatefulBuilder(
                builder: (sheetContext, setSheetState) {
                  final filtered = items
                      .where(
                        (item) => item.name.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                      )
                      .toList();

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(sheetContext).textTheme.titleLarge,
                          ),
                          if (!isAdding) ...[
                            const SizedBox(height: 8),
                            TextField(
                              onChanged: (value) =>
                                  setSheetState(() => query = value),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Type to filter',
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (allowClear)
                              ListTile(
                                title: const Text('Clear selection'),
                                onTap: () =>
                                    Navigator.of(dialogContext).pop(''),
                              ),
                            if (filtered.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('No inventory items found.'),
                              )
                            else
                              ...filtered.map(
                                (item) => ListTile(
                                  title: Text(item.name),
                                  onTap: () => Navigator.of(
                                    dialogContext,
                                  ).pop(item.name),
                                ),
                              ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('+ Add...'),
                              onTap: () => setSheetState(() {
                                isAdding = true;
                                errorText = null;
                                addController.clear();
                              }),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: addController,
                              decoration: InputDecoration(
                                labelText: label,
                                errorText: errorText,
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      isAdding = false;
                                      errorText = null;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () async {
                                    final trimmed = addController.text.trim();
                                    if (trimmed.isEmpty) {
                                      setSheetState(
                                        () => errorText = 'Enter a value',
                                      );
                                      return;
                                    }
                                    InventoryItem? existing;
                                    for (final item in items) {
                                      if (item.name.toLowerCase() ==
                                          trimmed.toLowerCase()) {
                                        existing = item;
                                        break;
                                      }
                                    }
                                    if (existing != null) {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(existing.name);
                                      return;
                                    }
                                    final now = DateTime.now();
                                    final item = InventoryItem(
                                      id: _uuid.v4(),
                                      type: type,
                                      name: trimmed,
                                      createdAt: now,
                                      updatedAt: now,
                                    );
                                    await context
                                        .read<InventoryRepository>()
                                        .upsertItem(item);
                                    debugPrint(
                                      'Saved inventory item [$type]: $trimmed',
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    Navigator.of(
                                      dialogContext,
                                    ).pop('$_inventoryAddedPrefix$trimmed');
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    await Future.delayed(const Duration(milliseconds: 150));
    addController.dispose();
    if (!mounted) {
      return null;
    }
    if (result == null) {
      return null;
    }
    if (result.isEmpty) {
      return '';
    }
    if (result.startsWith(_inventoryAddedPrefix)) {
      await _refreshData();
      return result.substring(_inventoryAddedPrefix.length);
    }
    return result;
  }

  String _inventoryLabelForType(String type) {
    switch (type) {
      case 'bullets':
        return 'Bullet';
      case 'brass':
        return 'Brass';
      case 'primers':
        return 'Primer';
      case 'powder':
        return 'Powder';
      case 'wads':
        return 'Wad';
      default:
        return 'Item';
    }
  }

  Future<LoadRecipe?> _saveRecipe({bool popOnSave = true}) async {
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    final isRifle = _selectedLoadType == LoadType.rifle;
    final isShotgun = _selectedLoadType == LoadType.shotgun;
    final isMuzzleloader = _selectedLoadType == LoadType.muzzleloader;

    if (isRifle && (_selectedPowder == null || _selectedPowder!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a powder.')));
      return null;
    }

    final shotgunPowderCharge = isShotgun
        ? double.parse(_shotgunPowderChargeController.text.trim())
        : null;
    final muzzlePowderCharge = isMuzzleloader
        ? double.parse(_muzzleloaderPowderChargeController.text.trim())
        : null;
    final powderChargeValue = isRifle
        ? double.parse(_powderChargeController.text.trim())
        : isShotgun
        ? shotgunPowderCharge!
        : muzzlePowderCharge!;
    final cartridgeValue = isRifle
        ? _cartridgeController.text.trim()
        : isShotgun
        ? _buildShotgunCartridge()
        : _muzzleloaderCaliberController.text.trim();
    final muzzleloaderPowderType = _selectedMuzzleloaderPowderType ?? '';
    final powderValue = isRifle
        ? _selectedPowder!
        : isShotgun
        ? _shotgunPowderController.text.trim()
        : muzzleloaderPowderType;
    final notesValue = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final now = DateTime.now();
    final recipe = LoadRecipe(
      id: _isEditing ? _editingRecipeId! : _uuid.v4(),
      recipeName: _recipeNameController.text.trim(),
      cartridge: cartridgeValue,
      bulletBrand: isRifle ? _selectedBullet : null,
      bulletWeightGr: isRifle
          ? double.tryParse(_bulletWeightController.text.trim())
          : null,
      bulletDiameter: isRifle
          ? double.tryParse(_bulletDiameterController.text.trim())
          : null,
      bulletType: isRifle && _bulletTypeController.text.trim().isNotEmpty
          ? _bulletTypeController.text.trim()
          : null,
      brass: isRifle ? _selectedBrass : null,
      brassTrimLength: isRifle
          ? double.tryParse(_brassTrimLengthController.text.trim())
          : null,
      annealingTimeSec: isRifle
          ? double.tryParse(_annealingTimeController.text.trim())
          : null,
      primer: isRifle ? _selectedPrimer : null,
      caseResize: isRifle ? _selectedCaseResize : null,
      gasCheckMaterial: isRifle ? _selectedGasCheckMaterial : null,
      gasCheckInstallMethod: isRifle ? _selectedGasCheckInstallMethod : null,
      bulletCoating: isRifle ? _selectedBulletCoating : null,
      powder: powderValue,
      powderChargeGr: powderChargeValue,
      coal: isRifle ? double.tryParse(_coalController.text.trim()) : null,
      baseToOgive: isRifle
          ? double.tryParse(_baseToOgiveController.text.trim())
          : null,
      seatingDepth: isRifle
          ? double.tryParse(_seatingDepthController.text.trim())
          : null,
      notes: notesValue,
      firearmId: _selectedFirearmId,
      loadType: _selectedLoadType,
      gauge: isShotgun ? _selectedGauge : null,
      shellLength: isShotgun ? _selectedShellLength : null,
      hull: isShotgun ? _optionalText(_shotgunHullController) : null,
      shotgunPrimer: isShotgun ? _optionalText(_shotgunPrimerController) : null,
      shotgunPowder: isShotgun ? _optionalText(_shotgunPowderController) : null,
      shotgunPowderCharge: isShotgun ? shotgunPowderCharge : null,
      wad: isShotgun ? _selectedWad : null,
      shotWeight: isShotgun
          ? _optionalText(_shotgunShotWeightController)
          : null,
      shotSize: isShotgun ? _optionalText(_shotgunShotSizeController) : null,
      shotType: isShotgun ? _selectedShotType : null,
      crimpType: isShotgun ? _selectedCrimpType : null,
      dramEquivalent: isShotgun
          ? double.tryParse(_shotgunDramEquivalentController.text.trim())
          : null,
      muzzleloaderCaliber: isMuzzleloader
          ? _optionalText(_muzzleloaderCaliberController)
          : null,
      ignitionType: isMuzzleloader ? _selectedIgnitionType : null,
      muzzleloaderPowderType: isMuzzleloader ? muzzleloaderPowderType : null,
      powderGranulation: isMuzzleloader ? _selectedPowderGranulation : null,
      muzzleloaderPowderCharge: isMuzzleloader ? muzzlePowderCharge : null,
      projectileType: isMuzzleloader ? _selectedProjectileType : null,
      projectileSizeWeight: isMuzzleloader
          ? _optionalText(_projectileSizeWeightController)
          : null,
      patchMaterial: isMuzzleloader && _selectedProjectileType == 'Round Ball'
          ? _optionalText(_patchMaterialController)
          : null,
      patchThickness: isMuzzleloader && _selectedProjectileType == 'Round Ball'
          ? _optionalText(_patchThicknessController)
          : null,
      patchLube: isMuzzleloader && _selectedProjectileType == 'Round Ball'
          ? _optionalText(_patchLubeController)
          : null,
      sabotType: isMuzzleloader && _selectedProjectileType == 'Sabot'
          ? _optionalText(_sabotTypeController)
          : null,
      cleanedBetweenShots: isMuzzleloader ? _cleanedBetweenShots : null,
      isKeeper: false,
      isDangerous: _isDangerous,
      dangerConfirmedAt: _dangerConfirmedAt,
      createdAt: _isEditing ? _editingCreatedAt! : now,
      updatedAt: now,
    );

    debugPrint('Saving load recipe ${recipe.id}');
    final repo = context.read<LoadRecipeRepository>();
    await repo.upsertRecipe(recipe);

    if (!mounted) {
      return recipe;
    }
    if (popOnSave) {
      Navigator.of(context).pop();
    }
    return recipe;
  }

  Future<void> _duplicateAndSave() async {
    if (_isDuplicateSaving) {
      return;
    }
    setState(() {
      _isDuplicateSaving = true;
    });
    final saved = await _saveRecipe(popOnSave: false);
    if (!mounted) {
      return;
    }
    if (saved == null) {
      setState(() {
        _isDuplicateSaving = false;
      });
      return;
    }
    final nextRecipe = saved.duplicateForNextEntry(
      newId: _uuid.v4(),
      now: DateTime.now(),
    );
    setState(() {
      _isEditing = false;
      _editingRecipeId = null;
      _editingCreatedAt = null;
      _applyRecipeToForm(nextRecipe);
      _isDuplicateSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved. Ready for next load.')),
    );
  }

  void _duplicateRecipe() {
    if (widget.recipe == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BuildLoadScreen(recipe: widget.recipe, isDuplicate: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing
        ? 'Edit Load'
        : widget.isDuplicate
        ? 'Duplicate Load'
        : 'Build Load';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FutureBuilder<_BuildLoadData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final firearms = data?.firearms ?? [];
            final inventoryByType = data?.inventoryByType ?? {};
            _syncInventoryControllers(inventoryByType);

            final brassItems = inventoryByType['brass'] ?? [];
            final bulletItems = inventoryByType['bullets'] ?? [];
            final wadItems = inventoryByType['wads'] ?? [];
            final powderItems = inventoryByType['powder'] ?? [];
            final primerItems = inventoryByType['primers'] ?? [];
            final customCaseResize = data?.customCaseResize ?? [];
            final customGasCheckMaterial = data?.customGasCheckMaterial ?? [];
            final customGasCheckInstallMethod =
                data?.customGasCheckInstallMethod ?? [];
            final customBulletCoating = data?.customBulletCoating ?? [];

            final trialService = context.watch<TrialService>();

            return KeyboardSafePage(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (trialService.shouldShowBanner())
                      TrialBanner(trialService: trialService),
                    TextFormField(
                      controller: _recipeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Recipe Name *',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<LoadType>(
                      segments: const [
                        ButtonSegment(
                          value: LoadType.rifle,
                          label: Text('Rifle/Pistol'),
                        ),
                        ButtonSegment(
                          value: LoadType.shotgun,
                          label: Text('Shotgun'),
                        ),
                        ButtonSegment(
                          value: LoadType.muzzleloader,
                          label: Text('Muzzleloader'),
                        ),
                      ],
                      selected: {_selectedLoadType},
                      showSelectedIcon: false,
                      onSelectionChanged: (selected) {
                        if (selected.isEmpty) {
                          return;
                        }
                        setState(() {
                          _selectedLoadType = selected.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue:
                                firearms.any(
                                  (firearm) => firearm.id == _selectedFirearmId,
                                )
                                ? _selectedFirearmId
                                : null,
                            items: firearms
                                .map(
                                  (firearm) => DropdownMenuItem<String?>(
                                    value: firearm.id,
                                    child: Text(firearm.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFirearmId = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Firearm',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _addFirearm,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectedLoadType == LoadType.rifle) ...[
                      TextFormField(
                        controller: _cartridgeController,
                        decoration: const InputDecoration(
                          labelText: 'Cartridge *',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bulletBrandController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Bullet',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () async {
                          final selected = await _pickInventoryItem(
                            title: 'Select Bullet',
                            items: bulletItems,
                            type: 'bullets',
                            allowClear: true,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _selectedBullet = selected.isEmpty
                                ? null
                                : selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bulletDiameterController,
                        decoration: const InputDecoration(
                          labelText: 'Bullet Diameter',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bulletWeightController,
                        decoration: const InputDecoration(
                          labelText: 'Bullet Weight (gr)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bulletTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Bullet Type',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _caseResizeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Case Resize',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () async {
                          final selected = await _pickCustomOption(
                            label: 'Case Resize',
                            prefsKey: SettingsKeys.caseResizeOptions,
                            predefinedOptions: _caseResizeOptions,
                            customOptions: customCaseResize,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _selectedCaseResize = selected;
                            _caseResizeController.text = selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gasCheckMaterialController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Gas Check Material',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () async {
                          final selected = await _pickCustomOption(
                            label: 'Gas Check Material',
                            prefsKey: SettingsKeys.gasCheckMaterialOptions,
                            predefinedOptions: _gasCheckMaterialOptions,
                            customOptions: customGasCheckMaterial,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _selectedGasCheckMaterial = selected;
                            _gasCheckMaterialController.text = selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gasCheckInstallMethodController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Gas Check Install Method',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () async {
                          final selected = await _pickCustomOption(
                            label: 'Gas Check Install Method',
                            prefsKey: SettingsKeys.gasCheckInstallMethodOptions,
                            predefinedOptions: _gasCheckInstallMethodOptions,
                            customOptions: customGasCheckInstallMethod,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _selectedGasCheckInstallMethod = selected;
                            _gasCheckInstallMethodController.text = selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bulletCoatingController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Bullet Coating',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () async {
                          final selected = await _pickCustomOption(
                            label: 'Bullet Coating',
                            prefsKey: SettingsKeys.bulletCoatingOptions,
                            predefinedOptions: _bulletCoatingOptions,
                            customOptions: customBulletCoating,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _selectedBulletCoating = selected;
                            _bulletCoatingController.text = selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _brassController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Brass',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () async {
                          final selected = await _pickInventoryItem(
                            title: 'Select Brass',
                            items: brassItems,
                            type: 'brass',
                            allowClear: true,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _selectedBrass = selected.isEmpty ? null : selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _brassTrimLengthController,
                        decoration: const InputDecoration(
                          labelText: 'Brass Trim Length',
                          helperText: 'Final case length after trimming',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _annealingTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Annealing time',
                          suffixText: 'sec',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _primerController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Primer',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () async {
                          final selected = await _pickInventoryItem(
                            title: 'Select Primer',
                            items: primerItems,
                            type: 'primers',
                            allowClear: true,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _selectedPrimer = selected.isEmpty
                                ? null
                                : selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _powderController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Powder *',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        validator: (_) =>
                            _selectedPowder == null || _selectedPowder!.isEmpty
                            ? 'Required'
                            : null,
                        onTap: () async {
                          final selected = await _pickInventoryItem(
                            title: 'Select Powder',
                            items: powderItems,
                            type: 'powder',
                            allowClear: false,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _selectedPowder = selected.isEmpty
                                ? null
                                : selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _powderChargeController,
                        decoration: const InputDecoration(
                          labelText: 'Powder Charge (gr) *',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _coalController,
                        decoration: const InputDecoration(labelText: 'COAL'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _baseToOgiveController,
                        decoration: const InputDecoration(
                          labelText: 'Base to Ogive (BTO)',
                          helperText:
                              'Measured from case head to bullet ogive using a comparator',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _seatingDepthController,
                        decoration: const InputDecoration(
                          labelText: 'Seating Depth',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_selectedLoadType == LoadType.shotgun) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGauge,
                        decoration: const InputDecoration(labelText: 'Gauge *'),
                        items: _shotgunGaugeOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGauge = value;
                          });
                        },
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedShellLength,
                        decoration: const InputDecoration(
                          labelText: 'Shell Length *',
                        ),
                        items: _shotgunShellLengthOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedShellLength = value;
                          });
                        },
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shotgunHullController,
                        decoration: const InputDecoration(labelText: 'Hull *'),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shotgunPrimerController,
                        decoration: const InputDecoration(
                          labelText: 'Primer *',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shotgunPowderController,
                        decoration: const InputDecoration(
                          labelText: 'Powder *',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shotgunPowderChargeController,
                        decoration: const InputDecoration(
                          labelText: 'Powder Charge (gr) *',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shotgunWadController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Wad *',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        validator: (_) =>
                            _selectedWad == null || _selectedWad!.isEmpty
                            ? 'Required'
                            : null,
                        onTap: () async {
                          final selected = await _pickInventoryItem(
                            title: 'Select Wad',
                            items: wadItems,
                            type: 'wads',
                            allowClear: true,
                          );
                          if (selected == null) {
                            return;
                          }
                          setState(() {
                            _selectedWad = selected.isEmpty ? null : selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shotgunShotWeightController,
                        decoration: const InputDecoration(
                          labelText: 'Shot Weight *',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shotgunShotSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Shot Size *',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedShotType,
                        decoration: const InputDecoration(
                          labelText: 'Shot Type *',
                        ),
                        items: _shotgunShotTypeOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedShotType = value;
                          });
                        },
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCrimpType,
                        decoration: const InputDecoration(
                          labelText: 'Crimp Type *',
                        ),
                        items: _shotgunCrimpTypeOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCrimpType = value;
                          });
                        },
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shotgunDramEquivalentController,
                        decoration: const InputDecoration(
                          labelText: 'Dram Equivalent',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_selectedLoadType == LoadType.muzzleloader) ...[
                      TextFormField(
                        controller: _muzzleloaderCaliberController,
                        decoration: const InputDecoration(
                          labelText: 'Caliber *',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedIgnitionType,
                        decoration: const InputDecoration(
                          labelText: 'Ignition Type *',
                        ),
                        items: _muzzleloaderIgnitionOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedIgnitionType = value;
                          });
                        },
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMuzzleloaderPowderType,
                        decoration: const InputDecoration(
                          labelText: 'Powder Type *',
                        ),
                        items: _muzzleloaderPowderTypeOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMuzzleloaderPowderType = value;
                          });
                        },
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPowderGranulation,
                        decoration: const InputDecoration(
                          labelText: 'Powder Granulation *',
                        ),
                        items: _muzzleloaderGranulationOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPowderGranulation = value;
                          });
                        },
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _muzzleloaderPowderChargeController,
                        decoration: const InputDecoration(
                          labelText: 'Powder Charge (gr by volume) *',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProjectileType,
                        decoration: const InputDecoration(
                          labelText: 'Projectile Type *',
                        ),
                        items: _muzzleloaderProjectileTypeOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProjectileType = value;
                          });
                        },
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _projectileSizeWeightController,
                        decoration: const InputDecoration(
                          labelText: 'Projectile Size/Weight *',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (_selectedProjectileType == 'Round Ball') ...[
                        TextFormField(
                          controller: _patchMaterialController,
                          decoration: const InputDecoration(
                            labelText: 'Patch Material',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _patchThicknessController,
                          decoration: const InputDecoration(
                            labelText: 'Patch Thickness',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _patchLubeController,
                          decoration: const InputDecoration(
                            labelText: 'Patch Lube',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_selectedProjectileType == 'Sabot') ...[
                        TextFormField(
                          controller: _sabotTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Sabot Type',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                      ],
                      CheckboxListTile(
                        value: _cleanedBetweenShots,
                        onChanged: (value) {
                          setState(() {
                            _cleanedBetweenShots = value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cleaned between shots'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        if (!_isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isDuplicateSaving
                                      ? null
                                      : _duplicateAndSave,
                                  child: const Text('Duplicate & Save'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveRecipe,
                                child: const Text('Save'),
                              ),
                            ),
                            if (_isEditing) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _duplicateRecipe,
                                  child: const Text('Duplicate Load'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BuildLoadData {
  const _BuildLoadData({
    required this.firearms,
    required this.inventoryByType,
    required this.customCaseResize,
    required this.customGasCheckMaterial,
    required this.customGasCheckInstallMethod,
    required this.customBulletCoating,
  });

  final List<Firearm> firearms;
  final Map<String, List<InventoryItem>> inventoryByType;
  final List<String> customCaseResize;
  final List<String> customGasCheckMaterial;
  final List<String> customGasCheckInstallMethod;
  final List<String> customBulletCoating;
}

class _AddFirearmDialog extends StatefulWidget {
  const _AddFirearmDialog();

  @override
  State<_AddFirearmDialog> createState() => _AddFirearmDialogState();
}

class _AddFirearmDialogState extends State<_AddFirearmDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  FirearmType _type = FirearmType.rifle;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Firearm'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FirearmType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              isExpanded: true,
              dropdownColor: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              iconEnabledColor: AppColors.secondary,
              style: Theme.of(context).textTheme.bodyLarge,
              items: FirearmType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _type = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            final firearm = Firearm(
              id: const Uuid().v4(),
              name: _nameController.text.trim(),
              type: _type,
            );
            Navigator.of(context).pop(firearm);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

const List<String> _caseResizeOptions = [
  'No Resize',
  'Neck Size Only',
  'Partial Full-Length',
  'Full-Length Resize',
  'Small Base Resize',
  'Base Die Resize',
  'Body Die Only',
  'Redding Competition / Bushing Die',
];

const List<String> _gasCheckMaterialOptions = [
  'None (Plain Base)',
  'Copper',
  'Gilding Metal',
  'Aluminum',
  'Brass',
  'Polymer / Hi-Tek',
  'Paper Patch',
  'Powder-Coat Base Only',
  'Experimental / Custom',
];

const List<String> _gasCheckInstallMethodOptions = [
  'None (Plain Base)',
  'Pressed On (Sizing Die)',
  'Crimped On',
  'Swaged On',
  'Push-Through Seated',
  'Glued (Epoxy / Adhesive)',
  'Baked On (Powder Coat or Hi-Tek)',
  'Paper Patched',
  'Experimental / Custom',
];

const List<String> _bulletCoatingOptions = [
  'None (Bare Lead)',
  'Wax / Grease Lube (Traditional)',
  'Powder Coat',
  'Hi-Tek Coating',
  'Polymer Jacket (Nylon / Polymer Dip)',
  'Moly Coated',
  'Hex Boron Nitride (hBN)',
  'Graphite Coated',
  'Paper Patch',
  'Electroplated (Thin Copper)',
  'Full Metal Jacket (FMJ)',
  'Jacketed Soft Point (JSP)',
  'Jacketed Hollow Point (JHP)',
  'Experimental / Custom',
];

const List<String> _shotgunGaugeOptions = [
  '10',
  '12',
  '16',
  '20',
  '28',
  '.410',
];

const List<String> _shotgunShellLengthOptions = ['2 3/4"', '3"', '3 1/2"'];

const List<String> _shotgunShotTypeOptions = [
  'Lead',
  'Steel',
  'Bismuth',
  'Tungsten',
];

const List<String> _shotgunCrimpTypeOptions = ['Star', 'Roll'];

const List<String> _muzzleloaderIgnitionOptions = [
  'Flintlock',
  'Percussion Cap',
];

const List<String> _muzzleloaderPowderTypeOptions = [
  'Black Powder (Real)',
  'Pyrodex',
  'Triple 7',
  'Blackhorn 209',
];

const List<String> _muzzleloaderGranulationOptions = [
  'Fg',
  'FFg',
  'FFFg',
  'FFFFg',
  'Pellet',
];

const List<String> _muzzleloaderProjectileTypeOptions = [
  'Round Ball',
  'Conical',
  'Sabot',
];
