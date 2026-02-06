import 'dart:io';

import 'package:flutter/material.dart';
import 'package:loadintel/core/widgets/keyboard_safe_page.dart';
import 'package:loadintel/domain/models/range_result.dart';
import 'package:loadintel/domain/models/target_photo.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/range_result_repository.dart';
import 'package:loadintel/domain/repositories/target_photo_repository.dart';
import 'package:loadintel/features/load_history/load_history_screen.dart';
import 'package:loadintel/features/range_test/models/range_test_entry.dart';
import 'package:loadintel/services/photo_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class DownRangeScreen extends StatefulWidget {
  const DownRangeScreen({
    super.key,
    required this.entries,
    required this.sessionNotes,
  });

  final List<RangeTestLoadEntry> entries;
  final String sessionNotes;

  @override
  State<DownRangeScreen> createState() => _DownRangeScreenState();
}

class _DownRangeScreenState extends State<DownRangeScreen> {
  final _uuid = const Uuid();
  final _photoService = PhotoService();
  late final List<_DownRangeEntryState> _states;

  String? _activeLoadId;

  @override
  void initState() {
    super.initState();
    _states = widget.entries
        .map((entry) => _DownRangeEntryState(benchEntry: entry))
        .toList();
    if (_states.isNotEmpty) {
      _activeLoadId = _states.first.benchEntry.recipe.id;
    }
  }

  @override
  void dispose() {
    for (final state in _states) {
      state.dispose();
    }
    super.dispose();
  }

  _DownRangeEntryState? _activeState() {
    if (_activeLoadId == null) {
      return null;
    }
    return _states.firstWhere((state) => state.benchEntry.recipe.id == _activeLoadId);
  }

  Future<void> _addPhoto(_DownRangeEntryState entry, Future<String?> Function() pick) async {
    final sourcePath = await pick();
    if (sourcePath == null) {
      return;
    }
    final savedPath = await _photoService.persistAndSave(sourcePath);
    if (savedPath == null) {
      return;
    }
    setState(() {
      entry.photoPaths.add(savedPath);
    });
  }

  Future<void> _saveResult(_DownRangeEntryState entry) async {
    final groupSize = double.tryParse(entry.groupSizeController.text.trim());
    if (groupSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter group size.')),
      );
      return;
    }
    final bench = entry.benchEntry;
    final firearmId = bench.firearmId;
    if (firearmId == null || bench.distanceYds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bench data incomplete.')),
      );
      return;
    }

    final now = DateTime.now();
    if (bench.isDangerous && !bench.recipe.isDangerous) {
      final updatedRecipe = bench.recipe.copyWith(
        isDangerous: true,
        dangerConfirmedAt: now,
        updatedAt: now,
      );
      await context.read<LoadRecipeRepository>().upsertRecipe(updatedRecipe);
    }
    final notes = _composeNotes(
      sessionNotes: widget.sessionNotes,
      loadNotes: entry.loadNotesController.text.trim(),
      isDangerous: bench.isDangerous,
      dangerReason: bench.dangerReason,
    );

    final result = RangeResult(
      id: _uuid.v4(),
      loadId: bench.recipe.id,
      testedAt: now,
      firearmId: firearmId,
      distanceYds: bench.distanceYds!,
      roundsTested: bench.roundsTested,
      fpsShots: bench.fpsMode == FpsEntryMode.shots ? bench.shots : null,
      avgFps: bench.avgFps,
      sdFps: bench.sdFps,
      esFps: bench.esFps,
      groupSizeIn: groupSize,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    final resultRepo = context.read<RangeResultRepository>();
    final photoRepo = context.read<TargetPhotoRepository>();

    await resultRepo.addResult(result);
    for (final path in entry.photoPaths) {
      await photoRepo.addPhoto(
        TargetPhoto(
          id: _uuid.v4(),
          rangeResultId: result.id,
          galleryPath: path,
          thumbPath: null,
        ),
      );
    }

    setState(() {
      entry.isSaved = true;
    });

    if (_states.every((state) => state.isSaved)) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Range Test Complete'),
          content: const Text('All results saved. Returning to Load History.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoadHistoryScreen()),
      );
    }
  }

  String? _composeNotes({
    required String sessionNotes,
    required String loadNotes,
    required bool isDangerous,
    required String? dangerReason,
  }) {
    final parts = <String>[];
    if (sessionNotes.isNotEmpty) {
      parts.add('Session: $sessionNotes');
    }
    if (loadNotes.isNotEmpty) {
      parts.add('Load: $loadNotes');
    }
    final dangerText = dangerReason?.trim() ?? '';
    if (dangerText.isNotEmpty) {
      parts.add('Danger: $dangerText');
    } else if (isDangerous) {
      parts.add('Danger: Marked dangerous.');
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final activeState = _activeState();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Down Range'),
      ),
      resizeToAvoidBottomInset: true,
      body: KeyboardSafePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Load',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _states.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final state = _states[index];
                  final isActive = state.benchEntry.recipe.id == _activeLoadId;
                  return InputChip(
                    label: Text(state.benchEntry.recipe.recipeName),
                    selected: isActive,
                    avatar: state.isSaved
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onSelected: (_) {
                      setState(() {
                        _activeLoadId = state.benchEntry.recipe.id;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (activeState == null)
              const Text('No loads available.')
            else
              _DownRangeEntryCard(
                entryState: activeState,
                sessionNotes: widget.sessionNotes,
                onAddCamera: () =>
                    _addPhoto(activeState, _photoService.pickFromCamera),
                onRemovePhoto: (path) {
                  setState(() {
                    activeState.photoPaths.remove(path);
                  });
                },
                onSave: activeState.isSaved ? null : () => _saveResult(activeState),
              ),
          ],
        ),
      ),
    );
  }
}

class _DownRangeEntryCard extends StatelessWidget {
  const _DownRangeEntryCard({
    required this.entryState,
    required this.sessionNotes,
    required this.onAddCamera,
    required this.onRemovePhoto,
    required this.onSave,
  });

  final _DownRangeEntryState entryState;
  final String sessionNotes;
  final VoidCallback onAddCamera;
  final ValueChanged<String> onRemovePhoto;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final bench = entryState.benchEntry;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bench.recipe.recipeName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Distance: ${bench.distanceYds?.toStringAsFixed(0) ?? '-'} yds'),
            Text('Rounds tested: ${bench.roundsTested?.toString() ?? '-'}'),
            Text(
              'AVG ${bench.avgFps?.toStringAsFixed(1) ?? '-'} '
              'SD ${bench.sdFps?.toStringAsFixed(1) ?? '-'} '
              'ES ${bench.esFps?.toStringAsFixed(1) ?? '-'}',
            ),
            const SizedBox(height: 12),
            Text(
              'Target Photos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PhotoAddButton(
                  label: 'Camera',
                  icon: Icons.camera_alt,
                  onPressed: onAddCamera,
                ),
              ],
            ),
            if (entryState.photoPaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entryState.photoPaths
                      .map(
                        (path) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => onRemovePhoto(path),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: entryState.groupSizeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Group Size (in)'),
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: entryState.loadNotesController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Load Notes'),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
            if (sessionNotes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Session Notes: $sessionNotes'),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                child: Text(entryState.isSaved ? 'Saved' : 'Save Result'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoAddButton extends StatelessWidget {
  const _PhotoAddButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _DownRangeEntryState {
  _DownRangeEntryState({required this.benchEntry});

  final RangeTestLoadEntry benchEntry;
  final TextEditingController groupSizeController = TextEditingController();
  final TextEditingController loadNotesController = TextEditingController();
  final List<String> photoPaths = [];
  bool isSaved = false;

  void dispose() {
    groupSizeController.dispose();
    loadNotesController.dispose();
  }
}
