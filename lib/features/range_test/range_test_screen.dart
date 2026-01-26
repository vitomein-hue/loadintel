import 'package:flutter/material.dart';
import 'package:loadintel/core/utils/fps_stats.dart';
import 'package:loadintel/domain/models/firearm.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/repositories/firearm_repository.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/features/build_load/build_load_screen.dart';
import 'package:loadintel/features/down_range/down_range_screen.dart';
import 'package:loadintel/features/range_test/models/range_test_entry.dart';
import 'package:provider/provider.dart';

class RangeTestScreen extends StatefulWidget {
  const RangeTestScreen({super.key, this.initialLoads = const []});

  final List<LoadRecipe> initialLoads;

  @override
  State<RangeTestScreen> createState() => _RangeTestScreenState();
}

class _RangeTestScreenState extends State<RangeTestScreen> {
  final List<RangeTestLoadEntry> _entries = [];
  final Map<String, RangeTestEntryController> _controllers = {};
  final TextEditingController _sessionNotesController = TextEditingController();

  String? _activeLoadId;
  late Future<List<Firearm>> _firearmsFuture;

  @override
  void initState() {
    super.initState();
    _firearmsFuture = context.read<FirearmRepository>().listFirearms();
    for (final recipe in widget.initialLoads) {
      _addEntry(recipe);
    }
    if (_entries.isNotEmpty) {
      _activeLoadId = _entries.first.recipe.id;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _sessionNotesController.dispose();
    super.dispose();
  }

  void _addEntry(LoadRecipe recipe) {
    if (_entries.any((entry) => entry.recipe.id == recipe.id)) {
      return;
    }
    final entry = RangeTestLoadEntry(
      recipe: recipe,
      firearmId: recipe.firearmId,
    );
    entry.distanceYds = 100;
    _entries.add(entry);
    final controller = RangeTestEntryController();
    controller.distanceController.text = '100';
    _controllers[recipe.id] = controller;
  }

  void _removeEntry(String loadId) {
    _entries.removeWhere((entry) => entry.recipe.id == loadId);
    _controllers.remove(loadId)?.dispose();
    if (_activeLoadId == loadId) {
      _activeLoadId = _entries.isNotEmpty ? _entries.first.recipe.id : null;
    }
    setState(() {});
  }

  Future<void> _confirmRemoveEntry(RangeTestLoadEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove load from test'),
        content: Text('Remove ${entry.recipe.recipeName} from this range test?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _removeEntry(entry.recipe.id);
    }
  }

  RangeTestLoadEntry? _activeEntry() {
    if (_activeLoadId == null) {
      return null;
    }
    return _entries.firstWhere((entry) => entry.recipe.id == _activeLoadId);
  }

  Future<void> _pickLoads() async {
    final repo = context.read<LoadRecipeRepository>();
    final available = await repo.listNewLoads();
    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<List<LoadRecipe>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _LoadPickerSheet(
        existingIds: _entries.map((e) => e.recipe.id).toSet(),
        loads: available,
        onBuildLoads: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BuildLoadScreen()),
          );
        },
      ),
    );

    if (selected == null || selected.isEmpty) {
      return;
    }

    setState(() {
      for (final recipe in selected) {
        _addEntry(recipe);
      }
      _activeLoadId ??= selected.first.id;
    });
  }

  Future<void> _switchMode(RangeTestLoadEntry entry, FpsEntryMode mode) async {
    if (entry.fpsMode == mode) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch entry mode?'),
        content: const Text(
          'Switching entry mode clears current FPS inputs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final controller = _controllers[entry.recipe.id];
    controller?.resetFps();
    setState(() {
      entry.fpsMode = mode;
      entry.avgFps = null;
      entry.sdFps = null;
      entry.esFps = null;
      entry.shots = [];
    });
  }

  void _updateManualValues(RangeTestLoadEntry entry) {
    final controller = _controllers[entry.recipe.id];
    if (controller == null) {
      return;
    }
    setState(() {
      entry.avgFps = double.tryParse(controller.avgController.text.trim());
      entry.sdFps = double.tryParse(controller.sdController.text.trim());
      entry.esFps = double.tryParse(controller.esController.text.trim());
    });
  }

  void _updateShots(RangeTestLoadEntry entry) {
    final controller = _controllers[entry.recipe.id];
    if (controller == null) {
      return;
    }
    final shots = controller.shotControllers
        .map((controller) => double.tryParse(controller.text.trim()))
        .whereType<double>()
        .toList();
    final stats = shots.length >= 2 ? computeFpsStats(shots) : null;
    setState(() {
      entry.shots = shots;
      entry.avgFps = stats?.average;
      entry.sdFps = stats?.sd;
      entry.esFps = stats?.es;
    });
  }

  bool _isBenchComplete(RangeTestLoadEntry entry) {
    if (entry.firearmId == null || entry.firearmId!.isEmpty) {
      return false;
    }
    if (entry.distanceYds == null) {
      return false;
    }
    if (entry.fpsMode == FpsEntryMode.manual) {
      return entry.avgFps != null;
    }
    return entry.shots.isNotEmpty;
  }

  bool get _allBenchComplete =>
      _entries.isNotEmpty && _entries.every(_isBenchComplete);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Range Test'),
      ),
      body: FutureBuilder<List<Firearm>>(
        future: _firearmsFuture,
        builder: (context, snapshot) {
          final firearms = snapshot.data ?? [];
          final activeEntry = _activeEntry();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Selected Loads',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickLoads,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Loads'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: _entries.isEmpty
                    ? const Center(child: Text('No loads selected.'))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          final isActive = entry.recipe.id == _activeLoadId;
                          return InputChip(
                            label: Text(
                              '${entry.recipe.recipeName} (${entry.recipe.powderChargeGr.toStringAsFixed(1)} gr)',
                            ),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            selected: isActive,
                            onSelected: (_) {
                              setState(() {
                                _activeLoadId = entry.recipe.id;
                              });
                            },
                            onDeleted: () => _confirmRemoveEntry(entry),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              if (activeEntry == null)
                const Text('Add a load to begin bench data entry.'),
              if (activeEntry != null)
                _BenchEntryCard(
                  entry: activeEntry,
                  firearms: firearms,
                  controller: _controllers[activeEntry.recipe.id]!,
                  onFirearmChanged: (value) {
                    setState(() {
                      activeEntry.firearmId = value;
                    });
                  },
                  onDistanceChanged: (value) {
                    setState(() {
                      activeEntry.distanceYds = value;
                    });
                  },
                  onModeChanged: (mode) => _switchMode(activeEntry, mode),
                  onManualChanged: () => _updateManualValues(activeEntry),
                  onShotsChanged: () => _updateShots(activeEntry),
                ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Notes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _sessionNotesController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Shared notes for this range test',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _allBenchComplete
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DownRangeScreen(
                          entries: _entries,
                          sessionNotes: _sessionNotesController.text.trim(),
                        ),
                      ),
                    );
                  }
                : null,
            child: const Text('Down Range'),
          ),
        ),
      ),
    );
  }
}

class _BenchEntryCard extends StatelessWidget {
  const _BenchEntryCard({
    required this.entry,
    required this.firearms,
    required this.controller,
    required this.onFirearmChanged,
    required this.onDistanceChanged,
    required this.onModeChanged,
    required this.onManualChanged,
    required this.onShotsChanged,
  });

  final RangeTestLoadEntry entry;
  final List<Firearm> firearms;
  final RangeTestEntryController controller;
  final ValueChanged<String?> onFirearmChanged;
  final ValueChanged<double?> onDistanceChanged;
  final ValueChanged<FpsEntryMode> onModeChanged;
  final VoidCallback onManualChanged;
  final VoidCallback onShotsChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.recipe.recipeName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: firearms.any((firearm) => firearm.id == entry.firearmId)
                  ? entry.firearmId
                  : null,
              decoration: const InputDecoration(labelText: 'Firearm'),
              items: firearms
                  .map(
                    (firearm) => DropdownMenuItem<String?>(
                      value: firearm.id,
                      child: Text(firearm.name),
                    ),
                  )
                  .toList(),
              onChanged: onFirearmChanged,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Distance (yds)'),
              onChanged: (value) => onDistanceChanged(double.tryParse(value.trim())),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: entry.fpsMode == FpsEntryMode.manual
                  ? OutlinedButton(
                      onPressed: () => onModeChanged(FpsEntryMode.shots),
                      child: const Text('Use Shot-by-shot'),
                    )
                  : OutlinedButton(
                      onPressed: () => onModeChanged(FpsEntryMode.manual),
                      child: const Text('Use Manual Summary'),
                    ),
            ),
            const SizedBox(height: 12),
            if (entry.fpsMode == FpsEntryMode.manual)
              Column(
                children: [
                  TextField(
                    controller: controller.avgController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'AVG FPS *'),
                    onChanged: (_) => onManualChanged(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.sdController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'SD FPS'),
                    onChanged: (_) => onManualChanged(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.esController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'ES FPS'),
                    onChanged: (_) => onManualChanged(),
                  ),
                ],
              ),
            if (entry.fpsMode == FpsEntryMode.shots)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...controller.shotControllers.asMap().entries.map((entryPair) {
                    final index = entryPair.key;
                    final shotController = entryPair.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: shotController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'Shot ${index + 1}'),
                        onChanged: (_) {
                          if (index == controller.shotControllers.length - 1 &&
                              shotController.text.trim().isNotEmpty) {
                            controller.addShotController();
                          }
                          onShotsChanged();
                        },
                      ),
                    );
                  }),
                  if (entry.shots.length >= 2)
                    Text(
                      'AVG ${entry.avgFps?.toStringAsFixed(1) ?? '-'} '
                      '| SD ${entry.sdFps?.toStringAsFixed(1) ?? '-'} '
                      '| ES ${entry.esFps?.toStringAsFixed(1) ?? '-'}',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadPickerSheet extends StatefulWidget {
  const _LoadPickerSheet({
    required this.loads,
    required this.existingIds,
    required this.onBuildLoads,
  });

  final List<LoadRecipe> loads;
  final Set<String> existingIds;
  final VoidCallback onBuildLoads;

  @override
  State<_LoadPickerSheet> createState() => _LoadPickerSheetState();
}

class _LoadPickerSheetState extends State<_LoadPickerSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final available = widget.loads
        .where((recipe) => !widget.existingIds.contains(recipe.id))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add Loads',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () {
                        final selected = available
                            .where((recipe) => _selectedIds.contains(recipe.id))
                            .toList();
                        Navigator.of(context).pop(selected);
                      },
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (available.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No additional new loads available.'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final recipe = available[index];
                  return CheckboxListTile(
                    value: _selectedIds.contains(recipe.id),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedIds.add(recipe.id);
                        } else {
                          _selectedIds.remove(recipe.id);
                        }
                      });
                    },
                    title: Text(recipe.recipeName),
                    subtitle: Text(recipe.cartridge),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onBuildLoads();
                  },
                  child: const Text('Build Loads'),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}

class RangeTestEntryController {
  RangeTestEntryController()
      : distanceController = TextEditingController(),
        avgController = TextEditingController(),
        sdController = TextEditingController(),
        esController = TextEditingController(),
        shotControllers = [TextEditingController()];

  final TextEditingController distanceController;
  final TextEditingController avgController;
  final TextEditingController sdController;
  final TextEditingController esController;
  final List<TextEditingController> shotControllers;

  void addShotController() {
    shotControllers.add(TextEditingController());
  }

  void resetFps() {
    avgController.clear();
    sdController.clear();
    esController.clear();
    for (final controller in shotControllers) {
      controller.dispose();
    }
    shotControllers
      ..clear()
      ..add(TextEditingController());
  }

  void dispose() {
    distanceController.dispose();
    avgController.dispose();
    sdController.dispose();
    esController.dispose();
    for (final controller in shotControllers) {
      controller.dispose();
    }
  }
}
