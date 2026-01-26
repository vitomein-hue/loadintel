import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _recipeNameController;
  late final TextEditingController _cartridgeController;
  late final TextEditingController _bulletBrandController;
  late final TextEditingController _bulletWeightController;
  late final TextEditingController _bulletTypeController;
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
    _bulletTypeController = TextEditingController(text: recipe?.bulletType ?? '');
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
    _bulletTypeController.dispose();
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
    final firearms = await firearmRepo.listFirearms();
    final items = await inventoryRepo.listItems();
    final inventoryByType = <String, List<InventoryItem>>{};
    for (final item in items) {
      inventoryByType.putIfAbsent(item.type, () => []).add(item);
    }
    for (final list in inventoryByType.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return _BuildLoadData(
      firearms: firearms,
      inventoryByType: inventoryByType,
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

  Future<String?> _pickInventoryItem({
    required String title,
    required List<InventoryItem> items,
    required String type,
    required bool allowClear,
  }) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        String query = '';
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
                            title: const Text('Add new'),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await _openInventory(type);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (result == null) {
      return null;
    }
    if (result.isEmpty) {
      return '';
    }
    return result;
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
      bulletType: _bulletTypeController.text.trim().isEmpty
          ? null
          : _bulletTypeController.text.trim(),
      brass: _selectedBrass,
      primer: _selectedPrimer,
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
  });

  final List<Firearm> firearms;
  final Map<String, List<InventoryItem>> inventoryByType;
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
