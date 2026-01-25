import 'dart:io';

import 'package:flutter/material.dart';
import 'package:loadintel/core/theme/app_colors.dart';
import 'package:loadintel/domain/models/firearm.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/load_with_best_result.dart';
import 'package:loadintel/domain/models/target_photo.dart';
import 'package:loadintel/domain/repositories/firearm_repository.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/target_photo_repository.dart';
import 'package:loadintel/features/build_load/build_load_screen.dart';
import 'package:loadintel/features/load_history/edit_result_screen.dart';
import 'package:loadintel/features/range_test/range_test_screen.dart';
import 'package:provider/provider.dart';

class LoadHistoryScreen extends StatefulWidget {
  const LoadHistoryScreen({super.key});

  @override
  State<LoadHistoryScreen> createState() => _LoadHistoryScreenState();
}

class _LoadHistoryScreenState extends State<LoadHistoryScreen> {
  late Future<_LoadHistoryData> _dataFuture;
  final Set<String> _selectedNewLoadIds = {};

  String? _filterCartridge;
  String? _filterPowder;
  double? _filterPowderCharge;
  double? _filterBulletWeight;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_LoadHistoryData> _loadData() async {
    final loadRepo = context.read<LoadRecipeRepository>();
    final firearmRepo = context.read<FirearmRepository>();
    final newLoads = await loadRepo.listNewLoads();
    final testedLoads = await loadRepo.listTestedLoads();
    final firearms = await firearmRepo.listFirearms();
    final firearmsById = {for (final firearm in firearms) firearm.id: firearm};
    return _LoadHistoryData(
      newLoads: newLoads,
      testedLoads: testedLoads,
      firearmsById: firearmsById,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  List<LoadRecipe> _applyRecipeFilters(List<LoadRecipe> recipes) {
    return recipes.where((recipe) {
      if (_filterCartridge != null && recipe.cartridge != _filterCartridge) {
        return false;
      }
      if (_filterPowder != null && recipe.powder != _filterPowder) {
        return false;
      }
      if (_filterPowderCharge != null && recipe.powderChargeGr != _filterPowderCharge) {
        return false;
      }
      if (_filterBulletWeight != null && recipe.bulletWeightGr != _filterBulletWeight) {
        return false;
      }
      return true;
    }).toList();
  }

  List<LoadWithBestResult> _applyTestedFilters(List<LoadWithBestResult> loads) {
    return loads.where((entry) {
      final recipe = entry.recipe;
      if (_filterCartridge != null && recipe.cartridge != _filterCartridge) {
        return false;
      }
      if (_filterPowder != null && recipe.powder != _filterPowder) {
        return false;
      }
      if (_filterPowderCharge != null && recipe.powderChargeGr != _filterPowderCharge) {
        return false;
      }
      if (_filterBulletWeight != null && recipe.bulletWeightGr != _filterBulletWeight) {
        return false;
      }
      return true;
    }).toList();
  }

  void _toggleSelection(String recipeId, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedNewLoadIds.add(recipeId);
      } else {
        _selectedNewLoadIds.remove(recipeId);
      }
    });
  }

  void _openRangeTest(List<LoadRecipe> selected) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RangeTestScreen(initialLoads: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load History'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_LoadHistoryData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No data yet.'));
          }

          final newLoads = _applyRecipeFilters(data.newLoads);
          final testedLoads = _applyTestedFilters(data.testedLoads);

          return Column(
            children: [
              _FilterRow(
                cartridges: _uniqueValues(data.newLoads, data.testedLoads, (r) => r.cartridge),
                powders: _uniqueValues(data.newLoads, data.testedLoads, (r) => r.powder),
                bulletWeights: _uniqueWeights(data.newLoads, data.testedLoads),
                powderCharges: _uniquePowderCharges(data.newLoads, data.testedLoads),
                selectedCartridge: _filterCartridge,
                selectedPowder: _filterPowder,
                selectedPowderCharge: _filterPowderCharge,
                selectedBulletWeight: _filterBulletWeight,
                onCartridgeChanged: (value) => setState(() => _filterCartridge = value),
                onPowderChanged: (value) => setState(() => _filterPowder = value),
                onPowderChargeChanged: (value) => setState(() => _filterPowderCharge = value),
                onBulletWeightChanged: (value) =>
                    setState(() => _filterBulletWeight = value),
                onMoreFilters: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => const _MoreFiltersSheet(),
                  );
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'New Loads',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (newLoads.isEmpty)
                      const Text('No new loads yet.'),
                    for (final recipe in newLoads)
                      Card(
                        child: CheckboxListTile(
                          value: _selectedNewLoadIds.contains(recipe.id),
                          onChanged: (value) => _toggleSelection(recipe.id, value),
                          title: Text(recipe.recipeName),
                          subtitle: Text(
                            '${recipe.cartridge} - ${_powderSummary(recipe)}',
                          ),
                          secondary: recipe.isDangerous
                              ? const Icon(Icons.flag, color: AppColors.danger)
                              : null,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Tested Loads',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (testedLoads.isEmpty)
                      const Text('No tested loads yet.'),
                    _TestedLoadsGrouped(
                      entries: testedLoads,
                      firearmsById: data.firearmsById,
                      photoRepo: context.read<TargetPhotoRepository>(),
                      onEditRecipe: (recipe) {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => BuildLoadScreen(
                                  recipe: recipe,
                                  isDuplicate: true,
                                ),
                              ),
                            )
                            .then((_) => _refresh());
                      },
                      onRefresh: _refresh,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _selectedNewLoadIds.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    final data = await _dataFuture;
                    final selected = data.newLoads
                        .where((recipe) => _selectedNewLoadIds.contains(recipe.id))
                        .toList();
                    if (selected.isEmpty) {
                      return;
                    }
                    _openRangeTest(selected);
                  },
                  child: const Text('Range Test'),
                ),
              ),
            ),
    );
  }
}

class _LoadHistoryData {
  const _LoadHistoryData({
    required this.newLoads,
    required this.testedLoads,
    required this.firearmsById,
  });

  final List<LoadRecipe> newLoads;
  final List<LoadWithBestResult> testedLoads;
  final Map<String, Firearm> firearmsById;
}

class _TestedLoadTile extends StatelessWidget {
  const _TestedLoadTile({
    required this.entry,
    required this.firearm,
    required this.photoRepo,
    required this.onEditRecipe,
    required this.onRefresh,
  });

  final LoadWithBestResult entry;
  final Firearm? firearm;
  final TargetPhotoRepository photoRepo;
  final VoidCallback onEditRecipe;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final recipe = entry.recipe;
    final bestResult = entry.bestResult;
    final bestGroup = bestResult?.groupSizeIn;
    final bestGroupLabel =
        bestGroup == null ? '-' : '${bestGroup.toStringAsFixed(2)} in';
    final firearmName = firearm?.name ?? 'Unknown';
    return Card(
      child: ExpansionTile(
        title: Text('${recipe.cartridge} - ${recipe.recipeName}'),
        subtitle: Text(
          '${_bulletSummary(recipe)} | ${_powderSummary(recipe)} | Best $bestGroupLabel | $firearmName',
        ),
        leading: recipe.isDangerous
            ? const Icon(Icons.flag, color: AppColors.danger)
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Firearm: ${firearm?.name ?? 'Unknown'}'),
                if (recipe.coal != null || recipe.seatingDepth != null)
                  Text('COAL: ${recipe.coal ?? '-'} | Seating: ${recipe.seatingDepth ?? '-'}'),
                if (bestResult != null)
                  Text(
                    'Best group: ${bestResult.groupSizeIn.toStringAsFixed(2)} in | '
                    'Tested: ${bestResult.testedAt.toLocal().toString().split(' ').first}',
                  ),
                if (bestResult != null)
                  Text(
                    'AVG: ${bestResult.avgFps?.toStringAsFixed(1) ?? '-'} | '
                    'SD: ${bestResult.sdFps?.toStringAsFixed(1) ?? '-'} | '
                    'ES: ${bestResult.esFps?.toStringAsFixed(1) ?? '-'}',
                  ),
                if (recipe.isDangerous)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'DANGEROUS!',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (bestResult != null)
                  FutureBuilder<List<TargetPhoto>>(
                    future: photoRepo.listPhotosForResult(bestResult.id),
                    builder: (context, snapshot) {
                      final photos = snapshot.data ?? [];
                      if (photos.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final photo = photos[index];
                              final path = photo.thumbPath ?? photo.galleryPath;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(path),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 64,
                                    height: 64,
                                    color: AppColors.card,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: onEditRecipe,
                      child: const Text('Clone Recipe'),
                    ),
                    if (bestResult != null)
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => EditResultScreen(result: bestResult),
                                ),
                              )
                              .then((_) => onRefresh());
                        },
                        child: const Icon(Icons.edit),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestedLoadsGrouped extends StatelessWidget {
  const _TestedLoadsGrouped({
    required this.entries,
    required this.firearmsById,
    required this.photoRepo,
    required this.onEditRecipe,
    required this.onRefresh,
  });

  final List<LoadWithBestResult> entries;
  final Map<String, Firearm> firearmsById;
  final TargetPhotoRepository photoRepo;
  final ValueChanged<LoadRecipe> onEditRecipe;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    String? currentCartridge;
    final widgets = <Widget>[];
    for (final entry in entries) {
      if (currentCartridge != entry.recipe.cartridge) {
        currentCartridge = entry.recipe.cartridge;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              currentCartridge!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }
      widgets.add(
        _TestedLoadTile(
          entry: entry,
          firearm: firearmsById[entry.recipe.firearmId],
          photoRepo: photoRepo,
          onEditRecipe: () => onEditRecipe(entry.recipe),
          onRefresh: onRefresh,
        ),
      );
    }
    return Column(children: widgets);
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.cartridges,
    required this.powders,
    required this.powderCharges,
    required this.bulletWeights,
    required this.selectedCartridge,
    required this.selectedPowder,
    required this.selectedPowderCharge,
    required this.selectedBulletWeight,
    required this.onCartridgeChanged,
    required this.onPowderChanged,
    required this.onPowderChargeChanged,
    required this.onBulletWeightChanged,
    required this.onMoreFilters,
  });

  final List<String> cartridges;
  final List<String> powders;
  final List<double> powderCharges;
  final List<double> bulletWeights;
  final String? selectedCartridge;
  final String? selectedPowder;
  final double? selectedPowderCharge;
  final double? selectedBulletWeight;
  final ValueChanged<String?> onCartridgeChanged;
  final ValueChanged<String?> onPowderChanged;
  final ValueChanged<double?> onPowderChargeChanged;
  final ValueChanged<double?> onBulletWeightChanged;
  final VoidCallback onMoreFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: selectedCartridge,
                  decoration: const InputDecoration(labelText: 'Cartridge'),
                  items: _dropdownItems(cartridges),
                  onChanged: onCartridgeChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: selectedPowder,
                  decoration: const InputDecoration(labelText: 'Powder'),
                  items: _dropdownItems(powders),
                  onChanged: onPowderChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<double?>(
                  value: selectedPowderCharge,
                  decoration: const InputDecoration(labelText: 'Powder Charge'),
                  items: [
                    const DropdownMenuItem<double?>(
                      value: null,
                      child: Text('Any'),
                    ),
                    ...powderCharges.map(
                      (charge) => DropdownMenuItem<double?>(
                        value: charge,
                        child: Text(charge.toStringAsFixed(1)),
                      ),
                    ),
                  ],
                  onChanged: onPowderChargeChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<double?>(
                  value: selectedBulletWeight,
                  decoration: const InputDecoration(labelText: 'Bullet Weight'),
                  items: [
                    const DropdownMenuItem<double?>(
                      value: null,
                      child: Text('Any'),
                    ),
                    ...bulletWeights.map(
                      (weight) => DropdownMenuItem<double?>(
                        value: weight,
                        child: Text(weight.toStringAsFixed(0)),
                      ),
                    ),
                  ],
                  onChanged: onBulletWeightChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onMoreFilters,
              icon: const Icon(Icons.tune),
              label: const Text('More Filters'),
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String?>> _dropdownItems(List<String> values) {
    return [
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Any'),
      ),
      ...values.map(
        (value) => DropdownMenuItem<String?>(
          value: value,
          child: Text(value),
        ),
      ),
    ];
  }

}

class _MoreFiltersSheet extends StatelessWidget {
  const _MoreFiltersSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More Filters',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Additional filters for bullet brand, primer, brass, danger flag, '
            'and result metrics will be added here.',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _uniqueValues(
  List<LoadRecipe> newLoads,
  List<LoadWithBestResult> testedLoads,
  String Function(LoadRecipe) selector,
) {
  final values = <String>{};
  for (final recipe in newLoads) {
    values.add(selector(recipe));
  }
  for (final entry in testedLoads) {
    values.add(selector(entry.recipe));
  }
  final list = values.toList();
  list.sort();
  return list;
}

List<double> _uniqueWeights(
  List<LoadRecipe> newLoads,
  List<LoadWithBestResult> testedLoads,
) {
  final values = <double>{};
  for (final recipe in newLoads) {
    if (recipe.bulletWeightGr != null) {
      values.add(recipe.bulletWeightGr!);
    }
  }
  for (final entry in testedLoads) {
    final weight = entry.recipe.bulletWeightGr;
    if (weight != null) {
      values.add(weight);
    }
  }
  final list = values.toList();
  list.sort();
  return list;
}

List<double> _uniquePowderCharges(
  List<LoadRecipe> newLoads,
  List<LoadWithBestResult> testedLoads,
) {
  final values = <double>{};
  for (final recipe in newLoads) {
    values.add(recipe.powderChargeGr);
  }
  for (final entry in testedLoads) {
    values.add(entry.recipe.powderChargeGr);
  }
  final list = values.toList();
  list.sort();
  return list;
}

String _powderSummary(LoadRecipe recipe) {
  return '${recipe.powder} ${recipe.powderChargeGr.toStringAsFixed(1)}gr';
}

String _bulletSummary(LoadRecipe recipe) {
  final parts = <String>[];
  if (recipe.bulletBrand != null && recipe.bulletBrand!.isNotEmpty) {
    parts.add(recipe.bulletBrand!);
  }
  if (recipe.bulletWeightGr != null) {
    parts.add('${recipe.bulletWeightGr!.toStringAsFixed(0)}gr');
  }
  if (recipe.bulletType != null && recipe.bulletType!.isNotEmpty) {
    parts.add(recipe.bulletType!);
  }
  if (parts.isEmpty) {
    return 'Bullet info';
  }
  return parts.join(' ');
}

