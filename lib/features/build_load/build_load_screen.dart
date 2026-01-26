import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:loadintel/core/theme/app_colors.dart';
import 'package:loadintel/core/utils/free_tier.dart';
import 'package:loadintel/domain/models/firearm.dart';
import 'package:loadintel/domain/models/inventory_item.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/repositories/firearm_repository.dart';
import 'package:loadintel/domain/repositories/inventory_repository.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/features/inventory/inventory_screen.dart';
import 'package:loadintel/services/purchase_service.dart';
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
  static const String _addNewOptionValue = '__add_new__';
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
  late final TextEditingController _primerController;
  late final TextEditingController _powderController;
  late final TextEditingController _powderChargeController;
  late final TextEditingController _coalController;
  late final TextEditingController _seatingDepthController;
  late final TextEditingController _notesController;

  String? _selectedFirearmId;
  String? _selectedBrass;
  String? _selectedBullet;
  String? _selectedPowder;
  String? _selectedPrimer;
  String? _selectedCaseResize;
  String? _selectedGasCheckMaterial;
  String? _selectedGasCheckInstallMethod;
  String? _selectedBulletCoating;

  bool _isDangerous = false;
  DateTime? _dangerConfirmedAt;
  late Future<_BuildLoadData> _dataFuture;

  bool get _isEditing => widget.recipe != null && !widget.isDuplicate;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    _recipeNameController = TextEditingController(text: recipe?.recipeName ?? '');
    _cartridgeController = TextEditingController(text: recipe?.cartridge ?? '');
    _bulletBrandController = TextEditingController(text: recipe?.bulletBrand ?? '');
    _bulletWeightController =
        TextEditingController(text: recipe?.bulletWeightGr?.toString() ?? '');
    _bulletDiameterController =
        TextEditingController(text: recipe?.bulletDiameter?.toString() ?? '');
    _bulletTypeController = TextEditingController(text: recipe?.bulletType ?? '');
    _caseResizeController = TextEditingController(text: recipe?.caseResize ?? '');
    _gasCheckMaterialController =
        TextEditingController(text: recipe?.gasCheckMaterial ?? '');
    _gasCheckInstallMethodController =
        TextEditingController(text: recipe?.gasCheckInstallMethod ?? '');
    _bulletCoatingController =
        TextEditingController(text: recipe?.bulletCoating ?? '');
    _brassController = TextEditingController(text: recipe?.brass ?? '');
    _primerController = TextEditingController(text: recipe?.primer ?? '');
    _powderController = TextEditingController(text: recipe?.powder ?? '');
    _powderChargeController =
        TextEditingController(text: recipe?.powderChargeGr.toString() ?? '');
    _coalController = TextEditingController(text: recipe?.coal?.toString() ?? '');
    _seatingDepthController =
        TextEditingController(text: recipe?.seatingDepth?.toString() ?? '');
    _notesController = TextEditingController(text: recipe?.notes ?? '');

    _selectedFirearmId = recipe?.firearmId;
    _selectedBrass = recipe?.brass;
    _selectedBullet = recipe?.bulletBrand;
    _selectedPowder = recipe?.powder;
    _selectedPrimer = recipe?.primer;
    _selectedCaseResize = recipe?.caseResize;
    _selectedGasCheckMaterial = recipe?.gasCheckMaterial;
    _selectedGasCheckInstallMethod = recipe?.gasCheckInstallMethod;
    _selectedBulletCoating = recipe?.bulletCoating;

    _isDangerous = recipe?.isDangerous ?? false;
    _dangerConfirmedAt = recipe?.dangerConfirmedAt;

    _dataFuture = _loadData();
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
    _primerController.dispose();
    _powderController.dispose();
    _powderChargeController.dispose();
    _coalController.dispose();
    _seatingDepthController.dispose();
    _notesController.dispose();
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
    final customCaseResize =
        await _loadCustomOptions(settingsRepo, SettingsKeys.caseResizeOptions);
    final customGasCheckMaterial =
        await _loadCustomOptions(settingsRepo, SettingsKeys.gasCheckMaterialOptions);
    final customGasCheckInstallMethod =
        await _loadCustomOptions(settingsRepo, SettingsKeys.gasCheckInstallMethodOptions);
    final customBulletCoating =
        await _loadCustomOptions(settingsRepo, SettingsKeys.bulletCoatingOptions);
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

  Future<void> _openInventory(String type) async {
    final category = InventoryCategory.byType(type);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryScreen(initialCategory: category.type),
      ),
    );
    await _refreshData();
  }

  String _displayInventoryValue(String? value, List<InventoryItem> items) {
    if (value == null || value.isEmpty) {
      return '';
    }
    final exists = items.any((item) => item.name == value);
    return exists ? value : '$value (missing)';
  }

  void _syncInventoryControllers(Map<String, List<InventoryItem>> inventoryByType) {
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
                                  Navigator.of(context)
                                      .pop('$_customOptionPrefix$trimmed');
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
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final filtered = items
                  .where(
                    (item) => item.name.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (!isAdding) ...[
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) => setSheetState(() => query = value),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Type to filter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            if (allowClear)
                              ListTile(
                                title: const Text('Clear selection'),
                                onTap: () => Navigator.of(context).pop(''),
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
                                  onTap: () => Navigator.of(context).pop(item.name),
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
                          ],
                        ),
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
                                setSheetState(() => errorText = 'Enter a value');
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
                                Navigator.of(context).pop(existing.name);
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
                              await context.read<InventoryRepository>().upsertItem(item);
                              debugPrint('Saved inventory item [$type]: $trimmed');
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context)
                                  .pop('$_inventoryAddedPrefix$trimmed');
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    addController.dispose();
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
      default:
        return 'Item';
    }
  }

  Future<bool> _canCreateRecipe() async {
    final loadRepo = context.read<LoadRecipeRepository>();
    final settingsRepo = context.read<SettingsRepository>();
    final unlocked = await settingsRepo.isLifetimeUnlocked();
    final count = await loadRepo.countRecipes();
    return canCreateRecipe(existingCount: count, isUnlocked: unlocked);
  }

  Future<void> _showUpgradeModal() async {
    final purchaseService = context.read<PurchaseService>();
    final priceLabel = purchaseService.lifetimeProduct?.price ?? 'Lifetime';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
          'Free tier is limited to 10 load recipes. Unlock lifetime access to add more.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              purchaseService.restore();
              Navigator.of(context).pop();
            },
            child: const Text('Restore'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              purchaseService.buyLifetime();
              Navigator.of(context).pop();
            },
            child: Text('Upgrade $priceLabel'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEditing) {
      final canCreate = await _canCreateRecipe();
      if (!canCreate) {
        await _showUpgradeModal();
        return;
      }
    }

    if (_selectedFirearmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a firearm.')),
      );
      return;
    }

    if (_selectedPowder == null || _selectedPowder!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a powder.')),
      );
      return;
    }

    final now = DateTime.now();
    final recipe = LoadRecipe(
      id: _isEditing ? widget.recipe!.id : _uuid.v4(),
      recipeName: _recipeNameController.text.trim(),
      cartridge: _cartridgeController.text.trim(),
      bulletBrand: _selectedBullet,
      bulletWeightGr: double.tryParse(_bulletWeightController.text.trim()),
      bulletDiameter: double.tryParse(_bulletDiameterController.text.trim()),
      bulletType: _bulletTypeController.text.trim().isEmpty
          ? null
          : _bulletTypeController.text.trim(),
      brass: _selectedBrass,
      primer: _selectedPrimer,
      caseResize: _selectedCaseResize,
      gasCheckMaterial: _selectedGasCheckMaterial,
      gasCheckInstallMethod: _selectedGasCheckInstallMethod,
      bulletCoating: _selectedBulletCoating,
      powder: _selectedPowder!,
      powderChargeGr: double.parse(_powderChargeController.text.trim()),
      coal: double.tryParse(_coalController.text.trim()),
      seatingDepth: double.tryParse(_seatingDepthController.text.trim()),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      firearmId: _selectedFirearmId!,
      isDangerous: _isDangerous,
      dangerConfirmedAt: _dangerConfirmedAt,
      createdAt: _isEditing ? widget.recipe!.createdAt : now,
      updatedAt: now,
    );

    debugPrint('Saving load recipe ${recipe.id}');
    final repo = context.read<LoadRecipeRepository>();
    await repo.upsertRecipe(recipe);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _duplicateRecipe() {
    if (widget.recipe == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BuildLoadScreen(
          recipe: widget.recipe,
          isDuplicate: true,
        ),
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
      appBar: AppBar(
        title: Text(title),
      ),
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
            final powderItems = inventoryByType['powder'] ?? [];
            final primerItems = inventoryByType['primers'] ?? [];
            final customCaseResize = data?.customCaseResize ?? [];
            final customGasCheckMaterial = data?.customGasCheckMaterial ?? [];
            final customGasCheckInstallMethod = data?.customGasCheckInstallMethod ?? [];
            final customBulletCoating = data?.customBulletCoating ?? [];

            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _recipeNameController,
                        decoration: const InputDecoration(labelText: 'Recipe Name *'),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cartridgeController,
                        decoration: const InputDecoration(labelText: 'Cartridge *'),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: firearms.any((firearm) => firearm.id == _selectedFirearmId)
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
                              decoration: const InputDecoration(labelText: 'Firearm *'),
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
                            _selectedBullet = selected.isEmpty ? null : selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bulletDiameterController,
                        decoration: const InputDecoration(
                          labelText: 'Bullet Diameter',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bulletWeightController,
                        decoration: const InputDecoration(labelText: 'Bullet Weight (gr)'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bulletTypeController,
                        decoration: const InputDecoration(labelText: 'Bullet Type'),
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
                            _selectedPrimer = selected.isEmpty ? null : selected;
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
                            _selectedPowder = selected.isEmpty ? null : selected;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _powderChargeController,
                        decoration: const InputDecoration(labelText: 'Powder Charge (gr) *'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
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
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _seatingDepthController,
                        decoration: const InputDecoration(labelText: 'Seating Depth'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              isExpanded: true,
              dropdownColor: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              iconEnabledColor: AppColors.secondary,
              style: Theme.of(context).textTheme.bodyLarge,
              items: FirearmType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    ),
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
