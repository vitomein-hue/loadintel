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
import 'package:loadintel/features/trial/trial_banner.dart';
import 'package:loadintel/services/trial_service.dart';
import 'package:provider/provider.dart';

class LoadHistoryScreen extends StatefulWidget {
  const LoadHistoryScreen({super.key});

  @override
  State<LoadHistoryScreen> createState() => _LoadHistoryScreenState();
}

class _LoadHistoryScreenState extends State<LoadHistoryScreen> {
  late Future<_LoadHistoryData> _dataFuture;
  final Set<String> _selectedNewLoadIds = {};
  bool _filtersExpanded = false;

  String? _filterCartridge;
  String? _filterPowder;
  double? _filterPowderCharge;
  double? _filterBulletWeight;
  String? _filterRecipeName;
  String? _filterFirearmId;
  String? _filterBulletBrand;
  double? _filterBulletDiameter;
  String? _filterBulletType;
  String? _filterBrass;
  String? _filterPrimer;
  String? _filterCaseResize;
  String? _filterGasCheckMaterial;
  String? _filterGasCheckInstallMethod;
  String? _filterBulletCoating;
  double? _filterCoal;
  double? _filterBaseToOgive;
  double? _filterSeatingDepth;
  String? _filterNotesQuery;
  bool? _filterIsDangerous;

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
      if (_filterRecipeName != null && recipe.recipeName != _filterRecipeName) {
        return false;
      }
      if (_filterFirearmId != null && recipe.firearmId != _filterFirearmId) {
        return false;
      }
      if (_filterBulletBrand != null &&
          recipe.bulletBrand != _filterBulletBrand) {
        return false;
      }
      if (_filterBulletDiameter != null &&
          recipe.bulletDiameter != _filterBulletDiameter) {
        return false;
      }
      if (_filterBulletType != null && recipe.bulletType != _filterBulletType) {
        return false;
      }
      if (_filterBrass != null && recipe.brass != _filterBrass) {
        return false;
      }
      if (_filterPrimer != null && recipe.primer != _filterPrimer) {
        return false;
      }
      if (_filterCaseResize != null && recipe.caseResize != _filterCaseResize) {
        return false;
      }
      if (_filterGasCheckMaterial != null &&
          recipe.gasCheckMaterial != _filterGasCheckMaterial) {
        return false;
      }
      if (_filterGasCheckInstallMethod != null &&
          recipe.gasCheckInstallMethod != _filterGasCheckInstallMethod) {
        return false;
      }
      if (_filterBulletCoating != null &&
          recipe.bulletCoating != _filterBulletCoating) {
        return false;
      }
      if (_filterPowder != null && recipe.powder != _filterPowder) {
        return false;
      }
      if (_filterPowderCharge != null &&
          recipe.powderChargeGr != _filterPowderCharge) {
        return false;
      }
      if (_filterBulletWeight != null &&
          recipe.bulletWeightGr != _filterBulletWeight) {
        return false;
      }
      if (_filterCoal != null && recipe.coal != _filterCoal) {
        return false;
      }
      if (_filterBaseToOgive != null &&
          recipe.baseToOgive != _filterBaseToOgive) {
        return false;
      }
      if (_filterSeatingDepth != null &&
          recipe.seatingDepth != _filterSeatingDepth) {
        return false;
      }
      if (_filterIsDangerous != null &&
          recipe.isDangerous != _filterIsDangerous) {
        return false;
      }
      final notesQuery = _filterNotesQuery?.trim();
      if (notesQuery != null && notesQuery.isNotEmpty) {
        final notes = recipe.notes ?? '';
        if (!notes.toLowerCase().contains(notesQuery.toLowerCase())) {
          return false;
        }
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
      if (_filterRecipeName != null && recipe.recipeName != _filterRecipeName) {
        return false;
      }
      if (_filterFirearmId != null && recipe.firearmId != _filterFirearmId) {
        return false;
      }
      if (_filterBulletBrand != null &&
          recipe.bulletBrand != _filterBulletBrand) {
        return false;
      }
      if (_filterBulletDiameter != null &&
          recipe.bulletDiameter != _filterBulletDiameter) {
        return false;
      }
      if (_filterBulletType != null && recipe.bulletType != _filterBulletType) {
        return false;
      }
      if (_filterBrass != null && recipe.brass != _filterBrass) {
        return false;
      }
      if (_filterPrimer != null && recipe.primer != _filterPrimer) {
        return false;
      }
      if (_filterCaseResize != null && recipe.caseResize != _filterCaseResize) {
        return false;
      }
      if (_filterGasCheckMaterial != null &&
          recipe.gasCheckMaterial != _filterGasCheckMaterial) {
        return false;
      }
      if (_filterGasCheckInstallMethod != null &&
          recipe.gasCheckInstallMethod != _filterGasCheckInstallMethod) {
        return false;
      }
      if (_filterBulletCoating != null &&
          recipe.bulletCoating != _filterBulletCoating) {
        return false;
      }
      if (_filterPowder != null && recipe.powder != _filterPowder) {
        return false;
      }
      if (_filterPowderCharge != null &&
          recipe.powderChargeGr != _filterPowderCharge) {
        return false;
      }
      if (_filterBulletWeight != null &&
          recipe.bulletWeightGr != _filterBulletWeight) {
        return false;
      }
      if (_filterCoal != null && recipe.coal != _filterCoal) {
        return false;
      }
      if (_filterBaseToOgive != null &&
          recipe.baseToOgive != _filterBaseToOgive) {
        return false;
      }
      if (_filterSeatingDepth != null &&
          recipe.seatingDepth != _filterSeatingDepth) {
        return false;
      }
      if (_filterIsDangerous != null &&
          recipe.isDangerous != _filterIsDangerous) {
        return false;
      }
      final notesQuery = _filterNotesQuery?.trim();
      if (notesQuery != null && notesQuery.isNotEmpty) {
        final notes = recipe.notes ?? '';
        if (!notes.toLowerCase().contains(notesQuery.toLowerCase())) {
          return false;
        }
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

  Future<void> _deleteSelectedLoads() async {
    if (_selectedNewLoadIds.isEmpty) {
      return;
    }

    final selectionCount = _selectedNewLoadIds.length;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Loads'),
            content: Text(
              'Delete $selectionCount selected load${selectionCount == 1 ? '' : 's'}? '
              'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final repo = context.read<LoadRecipeRepository>();
    final ids = List<String>.from(_selectedNewLoadIds);
    for (final id in ids) {
      await repo.deleteRecipe(id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedNewLoadIds.clear();
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load History'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
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

          final firearms = data.firearmsById.values.toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

          final bottomInset = MediaQuery.of(context).padding.bottom;
          
          final trialService = context.watch<TrialService>();
          
          return Column(
            children: [
              if (trialService.shouldShowBanner()) TrialBanner(trialService: trialService),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _filtersExpanded = !_filtersExpanded),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune),
                        const SizedBox(width: 8),
                        const Text('Filter loads'),
                        const SizedBox(width: 4),
                        Icon(
                          _filtersExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _filtersExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _FilterRow(
                  cartridges: _uniqueValues(
                    data.newLoads,
                    data.testedLoads,
                    (r) => r.cartridge,
                  ),
                  powders: _uniqueValues(
                    data.newLoads,
                    data.testedLoads,
                    (r) => r.powder,
                  ),
                  bulletWeights: _uniqueWeights(
                    data.newLoads,
                    data.testedLoads,
                  ),
                  powderCharges: _uniquePowderCharges(
                    data.newLoads,
                    data.testedLoads,
                  ),
                  selectedCartridge: _filterCartridge,
                  selectedPowder: _filterPowder,
                  selectedPowderCharge: _filterPowderCharge,
                  selectedBulletWeight: _filterBulletWeight,
                  onCartridgeChanged: (value) =>
                      setState(() => _filterCartridge = value),
                  onPowderChanged: (value) =>
                      setState(() => _filterPowder = value),
                  onPowderChargeChanged: (value) =>
                      setState(() => _filterPowderCharge = value),
                  onBulletWeightChanged: (value) =>
                      setState(() => _filterBulletWeight = value),
                  onMoreFilters: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (context) => _MoreFiltersSheet(
                        recipeNames: _uniqueValues(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.recipeName,
                        ),
                        firearms: firearms,
                        bulletBrands: _uniqueOptionalValues(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.bulletBrand,
                        ),
                        bulletDiameters: _uniqueOptionalDoubles(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.bulletDiameter,
                        ),
                        bulletTypes: _uniqueOptionalValues(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.bulletType,
                        ),
                        brass: _uniqueOptionalValues(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.brass,
                        ),
                        primers: _uniqueOptionalValues(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.primer,
                        ),
                        caseResize: _uniqueOptionalValues(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.caseResize,
                        ),
                        gasCheckMaterials: _uniqueOptionalValues(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.gasCheckMaterial,
                        ),
                        gasCheckInstallMethods: _uniqueOptionalValues(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.gasCheckInstallMethod,
                        ),
                        bulletCoatings: _uniqueOptionalValues(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.bulletCoating,
                        ),
                        coalValues: _uniqueOptionalDoubles(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.coal,
                        ),
                        baseToOgiveValues: _uniqueOptionalDoubles(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.baseToOgive,
                        ),
                        seatingDepthValues: _uniqueOptionalDoubles(
                          data.newLoads,
                          data.testedLoads,
                          (r) => r.seatingDepth,
                        ),
                        selectedRecipeName: _filterRecipeName,
                        selectedFirearmId: _filterFirearmId,
                        selectedBulletBrand: _filterBulletBrand,
                        selectedBulletDiameter: _filterBulletDiameter,
                        selectedBulletType: _filterBulletType,
                        selectedBrass: _filterBrass,
                        selectedPrimer: _filterPrimer,
                        selectedCaseResize: _filterCaseResize,
                        selectedGasCheckMaterial: _filterGasCheckMaterial,
                        selectedGasCheckInstallMethod:
                            _filterGasCheckInstallMethod,
                        selectedBulletCoating: _filterBulletCoating,
                        selectedCoal: _filterCoal,
                        selectedBaseToOgive: _filterBaseToOgive,
                        selectedSeatingDepth: _filterSeatingDepth,
                        selectedIsDangerous: _filterIsDangerous,
                        notesQuery: _filterNotesQuery ?? '',
                        onRecipeNameChanged: (value) =>
                            setState(() => _filterRecipeName = value),
                        onFirearmChanged: (value) =>
                            setState(() => _filterFirearmId = value),
                        onBulletBrandChanged: (value) =>
                            setState(() => _filterBulletBrand = value),
                        onBulletDiameterChanged: (value) =>
                            setState(() => _filterBulletDiameter = value),
                        onBulletTypeChanged: (value) =>
                            setState(() => _filterBulletType = value),
                        onBrassChanged: (value) =>
                            setState(() => _filterBrass = value),
                        onPrimerChanged: (value) =>
                            setState(() => _filterPrimer = value),
                        onCaseResizeChanged: (value) =>
                            setState(() => _filterCaseResize = value),
                        onGasCheckMaterialChanged: (value) =>
                            setState(() => _filterGasCheckMaterial = value),
                        onGasCheckInstallMethodChanged: (value) => setState(
                          () => _filterGasCheckInstallMethod = value,
                        ),
                        onBulletCoatingChanged: (value) =>
                            setState(() => _filterBulletCoating = value),
                        onCoalChanged: (value) =>
                            setState(() => _filterCoal = value),
                        onBaseToOgiveChanged: (value) =>
                            setState(() => _filterBaseToOgive = value),
                        onSeatingDepthChanged: (value) =>
                            setState(() => _filterSeatingDepth = value),
                        onNotesQueryChanged: (value) =>
                            setState(() => _filterNotesQuery = value),
                        onIsDangerousChanged: (value) =>
                            setState(() => _filterIsDangerous = value),
                      ),
                    );
                  },
                ),
                secondChild: const SizedBox.shrink(),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                  children: [
                    Text(
                      'New Loads',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (newLoads.isEmpty) const Text('No new loads yet.'),
                    for (final recipe in newLoads)
                      Card(
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: _selectedNewLoadIds.contains(recipe.id),
                              onChanged: (value) =>
                                  _toggleSelection(recipe.id, value),
                              title: Text(recipe.recipeName),
                              subtitle: Text(
                                '${recipe.cartridge} - ${_powderSummary(recipe)}',
                              ),
                              secondary: recipe.isDangerous
                                  ? const Icon(
                                      Icons.flag,
                                      color: AppColors.danger,
                                    )
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (_) => BuildLoadScreen(
                                                recipe: recipe,
                                                isDuplicate: false,
                                              ),
                                            ),
                                          )
                                          .then((_) => _refresh());
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                  ),
                                  if (_hasNotes(
                                    recipe,
                                    null,
                                    isDangerous: recipe.isDangerous,
                                  ))
                                    TextButton.icon(
                                      onPressed: () => _showLoadNotes(
                                        context,
                                        recipe.recipeName,
                                        recipeNotes: recipe.notes,
                                        resultNotes: null,
                                        isDangerous: recipe.isDangerous,
                                      ),
                                      icon: const Icon(Icons.notes),
                                      label: const Text('View Notes'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Tested Loads',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (testedLoads.isEmpty)
                      const Text('No tested loads yet.')
                    else
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
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _deleteSelectedLoads,
                        child: const Icon(Icons.delete),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final data = await _dataFuture;
                          final selected = data.newLoads
                              .where(
                                (recipe) =>
                                    _selectedNewLoadIds.contains(recipe.id),
                              )
                              .toList();
                          if (selected.isEmpty) {
                            return;
                          }
                          _openRangeTest(selected);
                        },
                        child: const Text('Range Test'),
                      ),
                    ),
                  ],
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
    final bestGroupLabel = bestGroup == null
        ? '-'
        : '${bestGroup.toStringAsFixed(2)} in';
    final firearmName = firearm?.name ?? 'Unknown';
    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(child: Text('${recipe.cartridge} - ${recipe.recipeName}')),
            if (recipe.isDangerous) ...[
              const SizedBox(width: 8),
              const _CautionBadge(),
            ],
          ],
        ),
        subtitle: Text(
          '${_bulletSummary(recipe)} | ${_powderSummary(recipe)} | Best $bestGroupLabel | $firearmName',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Firearm: ${firearm?.name ?? 'Unknown'}'),
                if (recipe.coal != null ||
                    recipe.baseToOgive != null ||
                    recipe.seatingDepth != null)
                  Text(
                    'COAL: ${recipe.coal ?? '-'} | BTO: ${recipe.baseToOgive ?? '-'} | Seating: ${recipe.seatingDepth ?? '-'}',
                  ),
                if (recipe.annealingTimeSec != null)
                  Text('Annealing Time: ${recipe.annealingTimeSec} sec'),
                if (recipe.caseResize != null && recipe.caseResize!.isNotEmpty)
                  Text('Case Resize: ${recipe.caseResize}'),
                if (recipe.gasCheckMaterial != null &&
                    recipe.gasCheckMaterial!.isNotEmpty)
                  Text('Gas Check Material: ${recipe.gasCheckMaterial}'),
                if (recipe.gasCheckInstallMethod != null &&
                    recipe.gasCheckInstallMethod!.isNotEmpty)
                  Text('Gas Check Install: ${recipe.gasCheckInstallMethod}'),
                if (recipe.bulletCoating != null &&
                    recipe.bulletCoating!.isNotEmpty)
                  Text('Bullet Coating: ${recipe.bulletCoating}'),
                if (bestResult != null)
                  Text(
                    'Best group: ${bestResult.groupSizeIn.toStringAsFixed(2)} in | '
                    'Tested: ${bestResult.testedAt.toLocal().toString().split(' ').first}',
                  ),
                if (bestResult != null)
                  Text('Rounds tested: ${bestResult.roundsTested ?? '-'}'),
                if (bestResult != null)
                  Text(
                    'AVG: ${bestResult.avgFps?.toStringAsFixed(1) ?? '-'} | '
                    'SD: ${bestResult.sdFps?.toStringAsFixed(1) ?? '-'} | '
                    'ES: ${bestResult.esFps?.toStringAsFixed(1) ?? '-'}',
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final photo = photos[index];
                              final path = photo.thumbPath ?? photo.galleryPath;
                              final heroTag = 'photo_${photo.id}';
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showPhotoFullscreen(
                                      context,
                                      photo,
                                      heroTag: heroTag,
                                    ),
                                    child: Hero(
                                      tag: heroTag,
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
                                          child: const Icon(
                                            Icons.image_not_supported,
                                          ),
                                        ),
                                      ),
                                    ),
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
                    if (_hasNotes(
                      recipe,
                      bestResult?.notes,
                      isDangerous: recipe.isDangerous,
                    ))
                      TextButton(
                        onPressed: () => _showLoadNotes(
                          context,
                          recipe.recipeName,
                          recipeNotes: recipe.notes,
                          resultNotes: bestResult?.notes,
                          isDangerous: recipe.isDangerous,
                        ),
                        child: const Text('View Notes'),
                      ),
                    if (bestResult != null)
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditResultScreen(result: bestResult),
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

class _CautionBadge extends StatelessWidget {
  const _CautionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        border: Border.all(color: AppColors.danger),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Caution',
        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
      ),
    );
  }
}

bool _hasNotes(
  LoadRecipe recipe,
  String? resultNotes, {
  required bool isDangerous,
}) {
  final hasRecipeNotes =
      recipe.notes != null && recipe.notes!.trim().isNotEmpty;
  final loadNotes = _extractTaggedNotes(resultNotes, 'Load');
  final sessionNotes = _extractTaggedNotes(resultNotes, 'Session');
  final dangerNotes = _extractTaggedNotes(resultNotes, 'Danger');
  return hasRecipeNotes ||
      (loadNotes != null && loadNotes.isNotEmpty) ||
      (sessionNotes != null && sessionNotes.isNotEmpty) ||
      (dangerNotes != null && dangerNotes.isNotEmpty) ||
      isDangerous;
}

String? _extractTaggedNotes(String? notes, String tag) {
  if (notes == null || notes.trim().isEmpty) {
    return null;
  }
  final lowerTag = '${tag.toLowerCase()}:';
  for (final line in notes.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.toLowerCase().startsWith(lowerTag)) {
      return trimmed.substring(lowerTag.length).trim();
    }
  }
  return null;
}

void _showLoadNotes(
  BuildContext context,
  String title, {
  String? recipeNotes,
  String? resultNotes,
  required bool isDangerous,
}) {
  final recipeText = recipeNotes?.trim();
  final loadNotes = _extractTaggedNotes(resultNotes, 'Load');
  final sessionNotes = _extractTaggedNotes(resultNotes, 'Session');
  final dangerNotes = _extractTaggedNotes(resultNotes, 'Danger');
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Notes - $title'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recipeText != null && recipeText.isNotEmpty) ...[
            const Text('Recipe Notes:'),
            const SizedBox(height: 4),
            Text(recipeText),
            const SizedBox(height: 12),
          ],
          if (loadNotes != null && loadNotes.isNotEmpty) ...[
            const Text('Load Notes:'),
            const SizedBox(height: 4),
            Text(loadNotes),
            const SizedBox(height: 12),
          ],
          if (dangerNotes != null && dangerNotes.isNotEmpty) ...[
            const Text('Danger:'),
            const SizedBox(height: 4),
            Text(dangerNotes),
            const SizedBox(height: 12),
          ] else if (isDangerous) ...[
            const Text('Danger:'),
            const SizedBox(height: 4),
            const Text('Marked dangerous.'),
            const SizedBox(height: 12),
          ],
          if (sessionNotes != null && sessionNotes.isNotEmpty) ...[
            const Text('Session Notes:'),
            const SizedBox(height: 4),
            Text(sessionNotes),
          ],
          if ((recipeText == null || recipeText.isEmpty) &&
              (loadNotes == null || loadNotes.isEmpty) &&
              (sessionNotes == null || sessionNotes.isEmpty) &&
              (dangerNotes == null || dangerNotes.isEmpty) &&
              !isDangerous)
            const Text('No notes available.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showPhotoFullscreen(
  BuildContext context,
  TargetPhoto photo, {
  required String heroTag,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          _FullScreenPhoto(path: photo.galleryPath, heroTag: heroTag),
    ),
  );
}

class _FullScreenPhoto extends StatelessWidget {
  const _FullScreenPhoto({required this.path, required this.heroTag});

  final String path;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.white70,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
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
    final widgets = <Widget>[];
    String? currentCartridge;
    for (final entry in entries) {
      if (currentCartridge != entry.recipe.cartridge) {
        currentCartridge = entry.recipe.cartridge;
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 12));
        }
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  currentCartridge,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Divider(height: 1)),
              ],
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
      const DropdownMenuItem<String?>(value: null, child: Text('Any')),
      ...values.map(
        (value) => DropdownMenuItem<String?>(value: value, child: Text(value)),
      ),
    ];
  }
}

class _MoreFiltersSheet extends StatelessWidget {
  const _MoreFiltersSheet({
    required this.recipeNames,
    required this.firearms,
    required this.bulletBrands,
    required this.bulletDiameters,
    required this.bulletTypes,
    required this.brass,
    required this.primers,
    required this.caseResize,
    required this.gasCheckMaterials,
    required this.gasCheckInstallMethods,
    required this.bulletCoatings,
    required this.coalValues,
    required this.baseToOgiveValues,
    required this.seatingDepthValues,
    required this.selectedRecipeName,
    required this.selectedFirearmId,
    required this.selectedBulletBrand,
    required this.selectedBulletDiameter,
    required this.selectedBulletType,
    required this.selectedBrass,
    required this.selectedPrimer,
    required this.selectedCaseResize,
    required this.selectedGasCheckMaterial,
    required this.selectedGasCheckInstallMethod,
    required this.selectedBulletCoating,
    required this.selectedCoal,
    required this.selectedBaseToOgive,
    required this.selectedSeatingDepth,
    required this.selectedIsDangerous,
    required this.notesQuery,
    required this.onRecipeNameChanged,
    required this.onFirearmChanged,
    required this.onBulletBrandChanged,
    required this.onBulletDiameterChanged,
    required this.onBulletTypeChanged,
    required this.onBrassChanged,
    required this.onPrimerChanged,
    required this.onCaseResizeChanged,
    required this.onGasCheckMaterialChanged,
    required this.onGasCheckInstallMethodChanged,
    required this.onBulletCoatingChanged,
    required this.onCoalChanged,
    required this.onBaseToOgiveChanged,
    required this.onSeatingDepthChanged,
    required this.onNotesQueryChanged,
    required this.onIsDangerousChanged,
  });

  final List<String> recipeNames;
  final List<Firearm> firearms;
  final List<String> bulletBrands;
  final List<double> bulletDiameters;
  final List<String> bulletTypes;
  final List<String> brass;
  final List<String> primers;
  final List<String> caseResize;
  final List<String> gasCheckMaterials;
  final List<String> gasCheckInstallMethods;
  final List<String> bulletCoatings;
  final List<double> coalValues;
  final List<double> baseToOgiveValues;
  final List<double> seatingDepthValues;
  final String? selectedRecipeName;
  final String? selectedFirearmId;
  final String? selectedBulletBrand;
  final double? selectedBulletDiameter;
  final String? selectedBulletType;
  final String? selectedBrass;
  final String? selectedPrimer;
  final String? selectedCaseResize;
  final String? selectedGasCheckMaterial;
  final String? selectedGasCheckInstallMethod;
  final String? selectedBulletCoating;
  final double? selectedCoal;
  final double? selectedBaseToOgive;
  final double? selectedSeatingDepth;
  final bool? selectedIsDangerous;
  final String notesQuery;
  final ValueChanged<String?> onRecipeNameChanged;
  final ValueChanged<String?> onFirearmChanged;
  final ValueChanged<String?> onBulletBrandChanged;
  final ValueChanged<double?> onBulletDiameterChanged;
  final ValueChanged<String?> onBulletTypeChanged;
  final ValueChanged<String?> onBrassChanged;
  final ValueChanged<String?> onPrimerChanged;
  final ValueChanged<String?> onCaseResizeChanged;
  final ValueChanged<String?> onGasCheckMaterialChanged;
  final ValueChanged<String?> onGasCheckInstallMethodChanged;
  final ValueChanged<String?> onBulletCoatingChanged;
  final ValueChanged<double?> onCoalChanged;
  final ValueChanged<double?> onBaseToOgiveChanged;
  final ValueChanged<double?> onSeatingDepthChanged;
  final ValueChanged<String> onNotesQueryChanged;
  final ValueChanged<bool?> onIsDangerousChanged;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset + keyboardInset),
        child: ListView(
          shrinkWrap: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
          Text('More Filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedRecipeName,
            decoration: const InputDecoration(labelText: 'Recipe Name'),
            items: _stringItems(recipeNames),
            onChanged: onRecipeNameChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedFirearmId,
            decoration: const InputDecoration(labelText: 'Firearm'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Any')),
              ...firearms.map(
                (firearm) => DropdownMenuItem<String?>(
                  value: firearm.id,
                  child: Text(firearm.name),
                ),
              ),
            ],
            onChanged: onFirearmChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedBulletBrand,
            decoration: const InputDecoration(labelText: 'Bullet'),
            items: _stringItems(bulletBrands),
            onChanged: onBulletBrandChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<double?>(
            value: selectedBulletDiameter,
            decoration: const InputDecoration(labelText: 'Bullet Diameter'),
            items: _doubleItems(bulletDiameters, decimals: 3),
            onChanged: onBulletDiameterChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedBulletType,
            decoration: const InputDecoration(labelText: 'Bullet Type'),
            items: _stringItems(bulletTypes),
            onChanged: onBulletTypeChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedCaseResize,
            decoration: const InputDecoration(labelText: 'Case Resize'),
            items: _stringItems(caseResize),
            onChanged: onCaseResizeChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedGasCheckMaterial,
            decoration: const InputDecoration(labelText: 'Gas Check Material'),
            items: _stringItems(gasCheckMaterials),
            onChanged: onGasCheckMaterialChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedGasCheckInstallMethod,
            decoration: const InputDecoration(
              labelText: 'Gas Check Install Method',
            ),
            items: _stringItems(gasCheckInstallMethods),
            onChanged: onGasCheckInstallMethodChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedBulletCoating,
            decoration: const InputDecoration(labelText: 'Bullet Coating'),
            items: _stringItems(bulletCoatings),
            onChanged: onBulletCoatingChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedBrass,
            decoration: const InputDecoration(labelText: 'Brass'),
            items: _stringItems(brass),
            onChanged: onBrassChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: selectedPrimer,
            decoration: const InputDecoration(labelText: 'Primer'),
            items: _stringItems(primers),
            onChanged: onPrimerChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<double?>(
            value: selectedCoal,
            decoration: const InputDecoration(labelText: 'COAL'),
            items: _doubleItems(coalValues, decimals: 3),
            onChanged: onCoalChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<double?>(
            value: selectedBaseToOgive,
            decoration: const InputDecoration(labelText: 'Base to Ogive (BTO)'),
            items: _doubleItems(baseToOgiveValues, decimals: 3),
            onChanged: onBaseToOgiveChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<double?>(
            value: selectedSeatingDepth,
            decoration: const InputDecoration(labelText: 'Seating Depth'),
            items: _doubleItems(seatingDepthValues, decimals: 3),
            onChanged: onSeatingDepthChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<bool?>(
            value: selectedIsDangerous,
            decoration: const InputDecoration(labelText: 'Dangerous'),
            items: const [
              DropdownMenuItem<bool?>(value: null, child: Text('Any')),
              DropdownMenuItem<bool?>(value: true, child: Text('Yes')),
              DropdownMenuItem<bool?>(value: false, child: Text('No')),
            ],
            onChanged: onIsDangerousChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: notesQuery,
            decoration: const InputDecoration(labelText: 'Notes contains'),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: onNotesQueryChanged,
            onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String?>> _stringItems(List<String> values) {
    return [
      const DropdownMenuItem<String?>(value: null, child: Text('Any')),
      ...values.map(
        (value) => DropdownMenuItem<String?>(value: value, child: Text(value)),
      ),
    ];
  }

  List<DropdownMenuItem<double?>> _doubleItems(
    List<double> values, {
    required int decimals,
  }) {
    return [
      const DropdownMenuItem<double?>(value: null, child: Text('Any')),
      ...values.map(
        (value) => DropdownMenuItem<double?>(
          value: value,
          child: Text(_formatDouble(value, decimals: decimals)),
        ),
      ),
    ];
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

List<String> _uniqueOptionalValues(
  List<LoadRecipe> newLoads,
  List<LoadWithBestResult> testedLoads,
  String? Function(LoadRecipe) selector,
) {
  final values = <String>{};
  for (final recipe in newLoads) {
    final value = selector(recipe);
    if (value != null && value.trim().isNotEmpty) {
      values.add(value);
    }
  }
  for (final entry in testedLoads) {
    final value = selector(entry.recipe);
    if (value != null && value.trim().isNotEmpty) {
      values.add(value);
    }
  }
  final list = values.toList();
  list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}

List<double> _uniqueOptionalDoubles(
  List<LoadRecipe> newLoads,
  List<LoadWithBestResult> testedLoads,
  double? Function(LoadRecipe) selector,
) {
  final values = <double>{};
  for (final recipe in newLoads) {
    final value = selector(recipe);
    if (value != null) {
      values.add(value);
    }
  }
  for (final entry in testedLoads) {
    final value = selector(entry.recipe);
    if (value != null) {
      values.add(value);
    }
  }
  final list = values.toList();
  list.sort();
  return list;
}

String _formatDouble(double value, {required int decimals}) {
  final fixed = value.toStringAsFixed(decimals);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
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
  if (recipe.bulletDiameter != null) {
    parts.add('${recipe.bulletDiameter}');
  }
  if (recipe.bulletType != null && recipe.bulletType!.isNotEmpty) {
    parts.add(recipe.bulletType!);
  }
  if (parts.isEmpty) {
    return 'Bullet info';
  }
  return parts.join(' ');
}
